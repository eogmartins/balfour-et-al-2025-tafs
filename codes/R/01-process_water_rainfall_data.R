# This code includes commands to assess relationships between water level data
# measured in the Toquaht River and rainfall data collected at Kennedy Camp 
# (~16 km from study site) in 2021. The processed data is then saved for use
# in the analysis of freshwater residence and survival.

# Initial setup ----
library(tidyverse)
library(lubridate)

# Read in data ----
toquaht <- read_csv("data/toquaht_water_level_data_2021.csv") %>%
  mutate(date = as.Date(date, format = "%m/%d/%Y"),
         yday = yday(date)) %>%
  group_by(date, yday) %>%
  summarize(mean_toquaht = mean(water_level))

kennedy <- read_csv("data/kennedy_camp_dailyrainfall_2021.csv") %>% 
  mutate(date = ymd(paste(year, month, day, sep = "-"))) %>%
  rename(rainfall = total_rain) %>%
  mutate(yday = yday(date)) %>%
  select(date, yday, rainfall)

# Compare rainfall at Kennedy Camp to Toquaht water levels ----

wl_data <- left_join(kennedy, toquaht, by = c("yday", "date")) %>%
  ungroup() %>%
  drop_na() %>%
  mutate(rainfall_l1 = lag(rainfall, 1),
         rainfall_l2 = lag(rainfall, 2),
         rainfall_l3 = lag(rainfall, 3),
         rainfall_l4 = lag(rainfall, 4),
         rainfall_l5 = lag(rainfall, 5)) %>%
  rename(rainfall_l0 = rainfall)

cor.test(~ rainfall_l0 + mean_toquaht, data = wl_data, na.action = "na.exclude")

cor.test(~ rainfall_l1 + mean_toquaht, data = wl_data, na.action = "na.exclude")

cor.test(~ rainfall_l2 + mean_toquaht, data = wl_data, na.action = "na.exclude")

cor.test(~ rainfall_l3 + mean_toquaht, data = wl_data, na.action = "na.exclude")

cor.test(~ rainfall_l4 + mean_toquaht, data = wl_data, na.action = "na.exclude")

cor.test(~ rainfall_l5 + mean_toquaht, data = wl_data, na.action = "na.exclude")

with(wl_data, plot(rainfall_l0, mean_toquaht))

with(wl_data, plot(rainfall_l1, mean_toquaht))

with(wl_data, plot(rainfall_l2, mean_toquaht))

with(wl_data, plot(rainfall_l3, mean_toquaht))

with(wl_data, plot(rainfall_l4, mean_toquaht))

with(wl_data, plot(rainfall_l5, mean_toquaht))

# The analyses above showed that Toquaht water level is positively correlated 
# (r = 0.76) with rainfall two days before. Below we save the data to model 
# detection efficiency at PIT antennas as a function of rainfall with lag 2.

wl_data <- select(wl_data, date, yday, mean_toquaht, rainfall_l2) %>%
  rename(mean_wl = mean_toquaht)

rf_data <- select(kennedy, date, yday, rainfall) %>%
  rename(rainfall_l0 = rainfall) %>%
  mutate(rainfall_l2 = lag(rainfall_l0, 2))

saveRDS(list(wl_data = wl_data, rf_data = rf_data), 
        "data/processed_wl_rf_data.rds")
