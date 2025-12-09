# Data Wrangling: Dendrometer Time-Series Processing

## Project Objective

This project reads multiple raw dendrometer `.csv` files from `data/Dendrometer_Data/`, combines them into a single tidy data frame, joins tree metadata from `data/gifford_dendro_tree_meta.csv`, and exports a cleaned, analysis-ready dataset as both `.rds` and `.csv`.  

All file paths use **relative paths** via `{here}`, so the script runs reproducibly on any machine without hard-coding absolute paths.

---

## Repository Structure

```text
project-root/
├─ scripts/
│  └─ data_processing.R          # R script that loads, tidies, and joins data
├─ data/
│  ├─ Dendrometer_Data/          # raw dendrometer .csv files (from loggers)
│  ├─ gifford_dendro_tree_meta.csv   # tree-level metadata (sensor → tree)
│  └─ processed/
│     └─ dendrometer_clean.rds   # cleaned dendrometer + metadata (output)
├─ data/Dendrometer_Data_clean.csv   # cleaned .csv export (output)
└─ README.md                     # this file
````

---

## Dependencies

* R ≥ 4.2
* Packages:

  * `{tidyverse}` (for `dplyr`, `readr`, `stringr`, etc.)
  * `{here}` (for project-root–relative file paths)
  * `{lubridate}` (for parsing datetimes)

You can install them (once) with:

```r
install.packages("tidyverse")
install.packages("here")
install.packages("lubridate")
```

---

## Script Overview (`scripts/data_processing.R`)

The script performs the following steps:

1. **Resolve project root** with `here()`.
2. **List** all raw `.csv` files in `data/Dendrometer_Data/`.
3. **Read & combine** all logger files into a single tibble with `readr::read_delim()`.
4. **Create `sensor_id`** by extracting digits from each filename (e.g., `"data_206.csv"` → `"206"`).
5. **Build a tidy table** with:

   * `record_id`, `sensor_id`
   * parsed `datetime`
   * `air_temp_C`
   * `radial_growth_um`
6. **Read tree metadata** from `data/gifford_dendro_tree_meta.csv` (mapping dendrometer → tree ID, species, DBH, lat/lon).
7. **Align names & join** metadata to the time series by `sensor_id`.
8. **Reorder columns** and drop the raw datetime string.
9. **Export outputs**:

   * `data/processed/dendrometer_clean.rds` (for R)
   * `data/Dendrometer_Data_clean.csv` (for inspection / grading)

---

## Script Used

```r
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
    # extract digits after 'data_' in the filename
    sensor_id = str_extract(basename(file), "(?<=data_)\\d+")
  )

## 3. Build tidy dendrometer table ---------------------------------------------
tidy_data <- all_data %>%
  transmute(
    record_id        = X1,
    sensor_id        = sensor_id,
    datetime_raw     = X2,
    # parse datetime like "2024.03.24 12:30"
    datetime         = parse_date_time(X2, "Y.m.d H:M"),
    air_temp_C       = X4,
    radial_growth_um = X7
  )

## 4. Read Gifford dendrometer metadata from CSV -------------------------------
meta_path <- here("data", "gifford_dendro_tree_meta.csv")

tree_meta <- readr::read_csv(
  meta_path,
  show_col_types = FALSE
)

## 5. Clean metadata, align column names ---------------------------------------
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
```

---

## How to Run

1. Open the project at the **repository root** (e.g., via an RStudio Project).

2. Ensure that:

   * Raw dendrometer `.csv` files are in: `data/Dendrometer_Data/`
   * Metadata file is in: `data/gifford_dendro_tree_meta.csv`

3. Run the processing script:

   ```r
   source(here::here("scripts", "data_processing.R"))
   ```

4. You should see a `glimpse()` summary of `dendro_clean`, and the following files created:

   * `data/processed/dendrometer_clean.rds`
   * `data/Dendrometer_Data_clean.csv`

These will be used in later assignments (e.g., data visualization, spatial mapping).

---

## Data Dictionary (cleaned output)

After running the script, `dendro_clean` has the following columns:

| Column             | Type      | Description                                                   |
| ------------------ | --------- | ------------------------------------------------------------- |
| `record_id`        | integer   | Original record index from logger file                        |
| `sensor_id`        | character | Dendrometer/logger ID extracted from filename (e.g., "206")   |
| `species_name`     | character | Tree species name                                             |
| `initial_dbh_cm`   | numeric   | Initial DBH at start of monitoring (cm)                       |
| `lat`              | numeric   | Tree latitude (decimal degrees, WGS84)                        |
| `lon`              | numeric   | Tree longitude (decimal degrees, WGS84)                       |
| `datetime`         | POSIXct   | Timestamp of measurement (parsed from logger datetime string) |
| `air_temp_C`       | numeric   | Air temperature at sensor (°C)                                |
| `radial_growth_um` | numeric   | Radial growth measurement (µm)                                |

---

## Common Issues & Fixes

* **`here()` points somewhere unexpected**

  * Make sure you’ve opened the project as an RStudio Project at the repo root, or call once per project:

    ```r
    here::i_am("README.md")
    ```

* **`cannot open the connection` for `data/Dendrometer_Data`**

  * Check that the folder exists and contains `.csv` files:

    ```r
    dir.exists(here("data", "Dendrometer_Data"))
    list.files(here("data", "Dendrometer_Data"))
    ```

* **`Metadata file not found` for `gifford_dendro_tree_meta.csv`**

  * Confirm that the metadata file is saved exactly as:
    `project-root/data/gifford_dendro_tree_meta.csv`
  * And that the column names match those used in `tree_meta_small`.
