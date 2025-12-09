################################################################################
# Assignment #2: Data Wrangling
################################################################################
# Isabella Childress
# iac63@miami.edu
# October 15, 2025
#
# Description
# EVR628 Assignment 2: Dendrometer data processing ---------------------------
# 1) Read raw dendrometer CSVs
# 2) Clean & tidy them
# 3) Read Gifford dendrometer metadata from data/gifford_dendro_tree_meta.csv
# 4) Join metadata to time series
# 5) Export clean .rds and .csv
################################################################################

## Load packages ---------------------------------------------------------------
library(tidyverse)
library(here)
library(lubridate)

## 0. Check project root -------------------------------------------------------
here()

## 1. Read and combine raw dendrometer CSVs -----------------------------------
dendro_csvs <- list.files(
  path    = here("data", "Dendrometer_Data"),  # folder with raw CSVs
  pattern = "\\.csv$",
  full.names = TRUE
)

## Read all CSVs into a single tibble
all_data <- readr::read_delim(
  file          = dendro_csvs,
  delim         = ";",
  col_names     = FALSE,
  id            = "file",          # adds 'file' column with source filename
  show_col_types = FALSE
)

## 2. Create sensor_id from file names -----------------------------------------
all_data <- all_data %>%
  mutate(
    ### extract digits after 'data_' in the filename
    sensor_id = str_extract(basename(file), "(?<=data_)\\d+")
  )

## 3. Build tidy dendrometer table ---------------------------------------------
tidy_data <- all_data %>%
  transmute(
    record_id        = X1,
    sensor_id        = sensor_id,
    datetime_raw     = X2,
    datetime         = parse_date_time(X2, "Y.m.d H:M"),
    air_temp_C       = X4,
    radial_growth_um = X7
  )

## 4. Read Gifford dendrometer metadata from CSV -------------------------------
# This assumes you saved the file as:
# data/gifford_dendro_tree_meta.csv

meta_path <- here("data", "gifford_dendro_tree_meta.csv")

tree_meta <- readr::read_csv(
  meta_path,
  show_col_types = FALSE
)

# Check columns so you can confirm names if needed
print(names(tree_meta))

## 5. Clean metadata, align column names ---------------------------------------
## Adjust names here if your CSV uses slightly different column names.

tree_meta_small <- tree_meta %>%
  transmute(
    sensor_id      = as.character(Dendrometer),
    species_name   = species,
    initial_dbh_cm = start_DBH,
    lat            = lat,
    lon            = lon
  )

## 6. Join metadata to dendrometer time series ---------------------------------
dendro_clean <- tidy_data %>%
  mutate(sensor_id = as.character(sensor_id)) %>%
  left_join(tree_meta_small, by = "sensor_id") %>%
  # Reorder to put metadata right after sensor_id
  relocate(species_name, initial_dbh_cm, lat, lon, .after = sensor_id) %>%
  # Drop unneeded raw datetime, keep parsed datetime
  select(-datetime_raw)

## Optional sanity check -------------------------------------------------------
glimpse(dendro_clean)

## 7. Create processed folder (if needed) --------------------------------------
dir.create(here("data", "processed"), showWarnings = FALSE)

## 8. Export cleaned data as .rds and .csv files--------------------------------
readr::write_rds(
  dendro_clean,
  here("data", "processed", "dendrometer_clean.rds")
)

readr::write_csv(
  dendro_clean,
  here("data", "Dendrometer_Data_clean.csv")
)
