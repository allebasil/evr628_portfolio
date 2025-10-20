# Data Wrangling: Dendrometer CSV Combiner

## Project Objective
This project reads multiple dendrometer `.csv` files from `data/Dendrometer_Data/`, combines them into a single data frame, and provides a quick structural check. It uses **relative paths** via `{here}` so the script runs reproducibly on any machine without changing file paths.

## Repository Structure
project-root/
├─ scripts/
│  └─ data_processing.R        # R script that loads & combines CSVs
├─ data/
│  └─ Dendrometer_Data/        # raw .csv files live here
└─ README.md                   # this file

## Dependencies
- R ≥ 4.2 version
- Packages: `{tidyverse}`, `{here}`

## Script Overview
1. Resolves paths relative to the project root with `here()`.
2. Lists all `.csv` files in `data/Dendrometer_Data/`.
3. Reads each file and row-binds them with `purrr::map_dfr()`.
4. Prints a compact structure of the first 10 columns.

**Script used**
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

## How to Run
1. Open the project at the **repository root** or set your working directory to the repo root.
2. Ensure CSVs are in `data/Dendrometer_Data/`.
3. Run:
       source(here::here("scripts", "data_processing.R"))
4. You should see `str()` output summarizing the combined data.

## Data Dictionary (fill in after first run)
Generate a starter table of column names and types:
    tibble::tibble(
      column_name = names(all_data),
      r_type      = vapply(all_data, function(x) class(x)[1], character(1)),
      description = ""  # <-- add concise descriptions here
    )

Template (edit as needed):

| Column | Type | Description |
|---|---|---|
| X1 | (e.g., character) | (e.g., tree ID) |
| X2 | (e.g., POSIXct)   | (e.g., timestamp in ISO-8601) |
| X3 | (e.g., double)    | (e.g., dendrometer reading; units = µm) |
| X4 |                    |                                  |
| …  |                    |                                  |

(Column names are not finalized, I'm using  `X1`, `X2`, … for now and update later.)

## Common Issues & Fixes
- **`cannot open file 'data': Permission denied`**
  - Run the project from the **repo root**; verify the path exists:
        dir.exists(here("data","Dendrometer_Data"))
  - On macOS/Linux, check folder permissions for `data/`.

- **`here()` points somewhere unexpected**
  - Open via an RStudio Project at the repo root, or explicitly set once per project:
        here::i_am("README.md")
