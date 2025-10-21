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

## Install packages
install.packages("tidyverse")
install.packages("here")


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
all_data <- purrr::map_dfr(dendro_csvs,
                           ~ readr::read_csv(.x, show_col_types = FALSE),
                           .id = NULL)

## Check this actually happened
str(all_data[, 1:10])
