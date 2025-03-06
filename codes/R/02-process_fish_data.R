# This code includes commands to read and process the raw tagging and detection 
# data to create detection histories. The data is then further processed to 
# generate data objects that will be bundled into a list for JAGS in code 
# 03-fit_model.R.

# Initial setup ----
options(digits = 15)
library(tidyverse)
library(clock)
library(lubridate)

# Process release data ----
tag <- read_csv("data/tagging_data.csv") %>%
  rename(rel_st = rel_site) %>%
  mutate(dist = case_when(rel_st == "B" ~ 4.1,
                          rel_st == "L" ~ 7.9,
                          rel_st == "UR" ~ 11.9),
         rel_st = recode(rel_st, B = "Lower River", L = "Lake", UR = "Upper River"),
         tag_id = as.character(tag_id * 1e12), # let's work without decimals
         rel_dt = (date_time_parse(rel_dt,
                                   format = "%m/%d/%Y %H:%M",
                                   zone = "America/Vancouver")))

# Identify IDs of fish with no length data
missing_length_id <- as.vector(na.exclude(tag[which(is.na(tag$length)),]$tag_id))

# Remove fish without tag_id and/or length
tag <- drop_na(tag, tag_id, length) 


# Process detection data ----
## Import upper reader/antenna detections ----
det02 <- read_csv("data/reader02_detections.csv") %>%
  mutate(det_dt = date_time_parse(paste(scan_date, scan_time, sep = " "),
                                  format = "%m/%d/%Y %H:%M:%S", 
                                  zone = "America/Vancouver"),
         tag_id = as.character(dec_id * 1e12)) %>%
  select(tag_id, det_dt, reader_id, antenna_id)


## Import lower reader/antenna detections ----
det01 <- read_csv("data/reader01_detections.csv") %>%
  mutate(det_dt = date_time_parse(paste(scan_date, scan_time, sep = " "),
                                  format = "%m/%d/%Y %H:%M:%S", 
                                  zone = "America/Vancouver"),
         tag_id = as.character(dec_id * 1e12)) %>%
  select(tag_id, det_dt, reader_id, antenna_id)


## Combine detections ----
det <- bind_rows(det02, det01) %>%
  distinct(tag_id, reader_id, .keep_all = TRUE) %>%
  # Make sure fish without length (n = 3) are not included in detection table
  filter(!(tag_id %in% missing_length_id)) 


## Make detection matrix ----
dh_rdr <- as.matrix(table(det$tag_id, det$reader_id)) 

dh_rdr <- tibble(tag_id = rownames(dh_rdr),
                 a2 = dh_rdr[, 2], # upper reader (must appear on left of a1)
                 a1 = dh_rdr[, 1]) # lower reader

dh_tmp <- select(tag, tag_id) %>%
  mutate(rel = 1) %>%
  left_join(dh_rdr, by = "tag_id") %>%
  mutate(a2 = ifelse(is.na(a2), 0, a2), # add non-detection
         a1 = ifelse(is.na(a1), 0, a1)) # add non-detection

dh <- as.matrix(select(dh_tmp, rel:a1))
rownames(dh) <- dh_tmp$tag_id


# Prepare data for analyses ----

## Freshwater residence data ----

# Get date/time a fish was last detected passing the array. Use this as the 
# fish's exit time
exit_time <- group_by(det, tag_id) %>%
  summarize(det_dt = max(det_dt))

res_dat <- tag %>%
  mutate(lower = ifelse(rel_st == "Lower River", 1, 0),
         upper = ifelse(rel_st == "Upper River", 1, 0),
         lake = ifelse(rel_st == "Lake", 1, 0),
         may23 = ifelse(as.Date(rel_dt) == "2021-05-23", 1, 0),
         june09 = ifelse(as.Date(rel_dt) == "2021-06-09", 1, 0),
         june19 = ifelse(as.Date(rel_dt) == "2021-06-19", 1, 0),
         rel_id = case_when(rel_st == "Lower River" & as.Date(rel_dt) == "2021-05-23" ~ 1,
                            rel_st == "Lake" & as.Date(rel_dt) == "2021-05-23" ~ 2,
                            rel_st == "Upper River" & as.Date(rel_dt) == "2021-05-23" ~ 3,
                            rel_st == "Lower River" & as.Date(rel_dt) == "2021-06-09" ~ 4,
                            rel_st == "Lake" & as.Date(rel_dt) == "2021-06-09" ~ 5,
                            rel_st == "Upper River" & as.Date(rel_dt) == "2021-06-09" ~ 6,
                            rel_st == "Lower River" & as.Date(rel_dt) == "2021-06-19" ~ 7,
                            rel_st == "Lake" & as.Date(rel_dt) == "2021-06-19" ~ 8,
                            rel_st == "Upper River" & as.Date(rel_dt) == "2021-06-19" ~ 9)) %>%
  left_join(exit_time, by = "tag_id") %>%
  mutate(fw_res = as.numeric(difftime(det_dt, rel_dt, units = "days")),
         rel_ydt = as.numeric(difftime(rel_dt, ymd_hms("2021-01-01 00:00:00", tz = "PDT"), 
                                       units = "days")) + 1) # add one to get the actual day, not the difference

## Detection history data ----

# Make sure detection history matrix includes only fish kept in res_dat
dh <- dh[which(rownames(dh) %in% res_dat$tag_id), ]

if(all.equal(rownames(dh), res_dat$tag_id) == FALSE) {
  stop("Detection history and data on fish are not aligned")
}

## Rainfall data ----

# Define minimum day of the year (i.e. when first fish was released)
min_yday <- yday(min(res_dat$rel_dt))

# Define maximum day of the year (i.e. 30 days after last detection, when 
# the array was taken down)
max_yday <- yday(max(res_dat$det_dt, na.rm = TRUE) + 84600 * 30)

# Read in and process rainfall data
rf_dat <- readRDS("data/processed_wl_rf_data.rds")$rf_data %>%
  # Rainfall on last two days of previous year
  rows_update(tibble(yday = 1:2, rainfall_l2 = c(1.8, 0))) %>% 
  # Rainfall data must be standardized with values for the study period only
  mutate(rainfall_l2_sdy = ifelse(between(yday, min_yday, max_yday), rainfall_l2, NA), 
         zrainfall_l2_sdy = (rainfall_l2_sdy - mean(rainfall_l2_sdy, na.rm = TRUE)) / 
           sd(rainfall_l2_sdy, na.rm = TRUE)) %>%
  drop_na(zrainfall_l2_sdy)

## Set the date the lower antenna was down ----
a1_down <- yday(ymd(c("2021-05-25", "2021-06-08")))
