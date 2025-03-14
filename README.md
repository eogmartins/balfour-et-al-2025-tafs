# Description

This repository contains data and codes associated with the article **Release strategies affect the freshwater residence and survival of hatchery-reared juvenile Chinook salmon (Oncorhynchus tshawytcha)**.

**IMPORTANT:** You will need to set up Git LFS when cloning this repository. This is required so you can download the model output file (`out_fit_dat.rds`), which is about 2GB in size. Once you have setup Git LFS (see instructions [here](https://docs.github.com/en/repositories/working-with-files/managing-large-files/installing-git-large-file-storage)), issue the command `git lfs pull` in an RStudio terminal, so the output file is downloaded, rather than just the pointer file.

[![DOI](https://zenodo.org/badge/944068586.svg)](https://doi.org/10.5281/zenodo.14984681)

## Data and file structure

The following raw data files were used in the analyses. Missing data are identified as NA.

**toquaht\_water\_level\_data\_2021.csv** - Data collected with a HOBO U20L level logger (Onset, Bourne, USA). The logger failed during deployment and only collected data between June 7th and 30th, 2021.

- *date*: Date of the record in the format mm/dd/yyyy.
- *time*: Time of the record in 24h format.
- *pre\_kpa\_20942062*: Water pressure recorded by the water level logger in kPa.
- *temp*: Water temperature recorded by the water level logger in °C.
- *pres\_kpa\_20942063*: Air pressure recorded by another HOBO U20L level logger deployed on land in kPa.
- *water_level*: Water level (depth) in meters converted from water pressured adjusted by removal of air pressure.

**kennedy\_camp\_dailyrainfall\_2021.csv** - Data file obtained from the Meteorological Service of Canada. Station Name: Ucluelet Kennedy Camp. Station ID: 1038332. Lon/Lat: -125.53, 48.95. The file contains rainfall data at a site located about 16 km from the PIT antenna array. These data were used as a proxy for water level at the antenna site in the Toquaht River, given that the water level logger failed and did not collect data for most of the study period. Only relevant columns from the downloaded dataset were kept. The Ucluelet Kennedy Camp weather station data are maintained by the Meteorological Service of Canada and can be accessed on their [website](https://climate.weather.gc.ca/historical_data/search_historic_data_stations_e.html?searchType=stnName&timeframe=1&txtStationName=kennedy+camp&searchMethod=contains&optLimit=yearRange&StartYear=1840&EndYear=2024&Year=2024&Month=6&Day=18&selRowPerPage=25)

- *year*: Year of the record.
- *month*: Month of the record.
- *day*: Day of the record.
- *total\_rain*: Total daily rainfall in mm.

**tagging\_data.csv** - Data file containing information on fish tagged in the study.

- *tag\_id*: Unique PIT tag code identifying the fish.
- *rel\_site*: Letter identifying the site where the fish was released. B (lower river), L (lake), UR (upper river).
- *rel\_dt*: Date and time when the fish was released in the format mm/dd/yyyy hh:mm (24h).
- *length*: Fork length of the fish in mm.
- *weight*: Weight of the fish in grams.

**reader01\_detections.csv** - Data file containing detection records at the *lower* reader/antenna.

- *scan\_date*: Date of the record in the format mm/dd/yyyy.
- *scan\_time*: Time of the record in the format hh:mm:ss.sss (24h).
- *download\_date*: Date that the data were downloaded in the format mm/dd/yyyy.
- *download\_time*: Time of the record in the format hh:mm:ss (24h).
- *reader\_id*: Integer identifying the reader (referred in the paper as antenna).
- *antenna\_id*: Integer identifying the antenna (single antenna and ignored in the paper).
- *dec_id*: Unique PIT tag code identifying the detected fish.

**reader02\_detections.csv** - Data file containing detection records at the *upper* reader/antenna.

- *scan\_date*: Date of the record in the format mm/dd/yyyy.
- *scan\_time*: Time of the record in the format hh:mm:ss.sss (24h).
- *download\_date*: Date that the data were downloaded in the format mm/dd/yyyy.
- *download\_time*: Time of the record in the format hh:mm:ss (24h).
- *reader\_id*: Integer identifying the reader (referred in the paper as antenna).
- *antenna\_id*: Integer identifying the antenna (single antenna and ignored in the paper).
- *dec_id*: Unique PIT tag code identifying the detected fish.

**processed_wl_rf_data.rds** - R Data Serialization file containing processed water level and preciptation data. This file is created with function **01-process\_water\_rainfall\_data.R**. The file is structured as a R list containing two elements. 
- *wl_data**: A data frame containing the variables associated with the water level data.
- *rf_data**: A data frame containing the variables associated with the precipitation data.

**out_fit_dat.rds** - R Data Serialization file containing the data and outputs of the model presented in the manuscript. They are organized in a R list containing two elements.

- *fit*: A jagsUI oobject containing the posterior samples of model parameters obtained by JAGS.
- *jfit*: A R list containing the list of data sent to JAGS via jagsUI.

## Code/Software

The analyses were conducted using JAGS 4.3.0 via the R package jagsUI 1.5.2 in R 4.3.1. Data processing as well as summaries and visualization of results were conducted in R 4.3.1 using packages tidyverse 2.0.0, clock 0.7.0, lubridate 1.9.3, ggfan 0.1.4, RColorBrewer 1.1.3, HDInterval 0.2.4, ggdist 3.3.1, gridExtra 2.3, grid 4.3.2, MCMCvis 0.16.3, and bayesplot 1.10.0.

The following files contain code to process and analyze the data and visualize the results:

- **model.R**: BUGS code of the integrated freshwater residence (generalized gamma GLM) and state-space CJS model of survival and detection.
 
- **00-function\_init\_z.R**: Function used when preparing data for JAGS using code in file **03-fit\_model.R** (see description below). It creates initial values for the fish state. This is based on the function found in the book Bayesian Population Analysis Using WinBUGS: A Hierarchical Perspective by Kéry and Schaub (2012).

- **00-function\_known\_state.R**: Function used when preparing data for JAGS using code in file **03-fit\_model.R** (see description below). It inputs known states for the fish in the state matrix. This is based on the function found in the book Bayesian Population Analysis Using WinBUGS: A Hierarchical Perspective by Kéry and Schaub (2012).

- **01-process\_water\_rainfall\_data.R**: R code to read and process rainfall and water level data (**toquaht\_water\_level\_data\_2021.csv** and **kennedy\_camp\_dailyrainfall\_2021.csv**) as well as evaluate relationships between water level and lagged rainfall. The processed data is saved to a .rds file to be used with R code *02-process_fish_data.R* (see decription below). 

- **02-process\_fish\_data.R**: R code to read and process raw tagging (**tagging\_data.csv**) and detection data (**reader01\_detections.csv** and **reader02\_detections.csv**). These data as well as the processed rainfal and waterlevel data are then further processed to create vector and matrices of data and constants to be used in fitting the model with JAGS. 

- **03-fit\_model.R** R code to define MCMC settings and monitors, bundle the data into a list, create an initial values function and run the model in JAGS. The model output is saved into a .rds file for checking, summarizing and visualizing the results.

- **04-check\_model.qmd**: Quarto file with commands to check MCMC chains and model diagnostics. It requires the output produced by the model fit in JAGS with **03-fit\_model.R** (i.e., **out_fit_dat.rds**).

- **05-plot\_freshwater\_residence.R**: R code to summarize and plot model predictions related to freshwater residence. It requires processed data generated by **02-process\_fish\_data.R** and the output produced by the model fit in JAGS with **03-fit\_model.R** (i.e., **out_fit_dat.rds**).

- **06-plot\_survival.R**: R code to summarize and plot model predictions related to freshwater survival. It requires processed data generated by **02-process\_fish\_data.R** and the output produced by the model fit in JAGS with **03-fit\_model.R** (i.e., **out_fit_dat.rds**).

- **07-plot\_supplement\_s1.R**: R code to plot posterior predictive checks presented in Supplement S1. It requires the output produced by the model fit in JAGS with **03-fit\_model.R** (i.e., **out_fit_dat.rds**).

- **08-plot\_supplement\_s2.R**: R code to summarize estimates for Table S1 and plot figures S1-S3 in Supplement S2. model estimates and predictions related to freshwater survival. It requires processed data generated by **02-process\_fish\_data.R** and the output produced by the model fit in JAGS with **03-fit\_model.R** (i.e., **out_fit_dat.rds**).

## Important instructions

After cloning thies repository, create a 'plots' folder that will be used to save the figures created with **05-plot\_freshwater\_residence.R**, **06-plot\_survival.R**, **07-plot\_supplement\_s1.R**, and **08-plot\_supplement\_s2.R**:.

```
project
├── codes
│   ├── JAGS
│   │   └── model.R
│   └── R
│       ├── 00-function_init_z.R
│       ├── 00-function_known_state.R
│       ├── 01-process_water_rainfall_data.R
│       ├── 02-process_fish_data.R
│       ├── 03-fit_model.R
│       ├── 04-check_model.qmd
│       ├── 05-plot_freshwater_residence.R
│       ├── 06-plot_survival.R
│       ├── 07-plot_supplement_s1.R
│       └── 08-plot_supplement_s2.R
├── data
│   ├── kennedy_camp_dailyrainfall_2021.csv
│   ├── reader01_detections.csv
│   ├── reader02_detections.csv
│   ├── tagging_data.csv
│   └── toquaht_water_level_data_2021.csv
├── plots
└── outputs
│   └── out_fit_dat.rds
```

## License

This project is licensed under the following terms:

- **Code**: The code in this repository is licensed under the [GNU General Public License v3.0 (GPL-3.0)](https://www.gnu.org/licenses/gpl-3.0.html). This means you are free to use, modify, and distribute the code, but any derivative work must also be released under the same license.
- **Data**: The data in this repository is licensed under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/). You are free to share and adapt the data, provided that you give appropriate credit.

By using this repository, you agree to comply with the terms of these licenses. 
