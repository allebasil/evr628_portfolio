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

## Check this actually happened
str(all_data[, 1:10])

##
