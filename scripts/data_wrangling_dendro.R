################################################################################
# Assignment #2: Data Wrangling
################################################################################
# Isabella Childress
# iac63@miami.edu
# October 15, 2025
#
# Description
#
################################################################################
# Pre-steps

## Load packages
library(tidyverse)
library(here)

## Inspect where 'here()' points (project root)
here()


## List the CSVs
dendro_csvs <- list.files(path = here("data", "Dendrometer_Data"),
                          pattern = "\\.csv$",
                          full.names = TRUE)


## Read & combine all CSVs
all_data <- readr::read_csv(dendro_csvs,
                            col_names = FALSE,
                            show_col_types = FALSE)

### Optional: Check this actually happened
str(all_data[, 1:10])

## Clean the data (rearrange and title columns, etc.)
### This is the actual cleaning!!!!! Note to self: Here is where you're doing it!
### I plan to create an object called "clean_data" and that will be the cleaned
### data ready to export
### clean_data <- all_data |>
  # e.g. rename columns, filter bad rows, parse dates, etc.
  # dplyr::rename(...)
  # dplyr::filter(...)
  # dplyr::mutate(...)

## Export cleaned version of data
readr::write_csv(all_data, here("data", "Dendrometer_Data_clean.csv"))
