################################################################################
# Visualizing spatial data for dendrometers
################################################################################
# Izzie Childress
# EVR 628 - Assignment 4
# December 9, 2025
#
# This script uses the dendro_clean dataset to compute tree-level metadata for
# Gifford Arboretum dendrometer trees (location, species, estimated current
# DBH and DBH increment), converts them to sf points, maps their locations
# and stem diameters on an external basemap, and exports the resulting
# study-site figure as a .png file for use in the final project.
################################################################################

# SET UP #######################################################################

## Load packages ---------------------------------------------------------------
library(tidyverse)
library(here)
library(readr)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggspatial)

## Set global theme ----------------------------------------------------------------
theme_set(theme_bw(base_size = 12))

## File paths ------------------------------------------------------------------
dendro_clean_path <- here("data", "processed", "dendrometer_clean.rds")

# DATA IMPORT & TREE-LEVEL METADATA ###########################################

## Read in processed dendrometer data -----------------------------------------
dendro_clean <- readr::read_rds(dendro_clean_path)

# Columns expected:
# record_id, sensor_id, species_name, initial_dbh_cm,
# lat, lon, datetime, air_temp_C, radial_growth_um

## Collapse to one row per sensor / tree ---------------------------------------
# For each sensor:
#  - keep species, location, initial DBH
#  - take max radial growth (µm)
#  - convert to DBH increment and estimated current DBH (cm)
dendro_sites <- dendro_clean %>%
  group_by(sensor_id, species_name, initial_dbh_cm, lat, lon) %>%
  summarise(
    max_radial_growth_um = max(radial_growth_um, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    # radial_growth_um is change in radius (µm); 1 µm = 1e-4 cm
    delta_radius_cm = max_radial_growth_um * 1e-4,
    delta_dbh_cm    = 2 * delta_radius_cm,
    current_dbh_cm  = initial_dbh_cm + delta_dbh_cm
  ) %>%
  rename(
    species        = species_name,
    dbh_current_cm = current_dbh_cm,
    dbh_change_cm  = delta_dbh_cm
  ) %>%
  select(sensor_id, species, dbh_current_cm, dbh_change_cm, lat, lon) %>%
  filter(
    !is.na(lat),
    !is.na(lon),
    !is.na(dbh_current_cm),
    !is.na(dbh_change_cm)
  )

## Convert to sf object --------------------------------------------------------
dendro_sf <- dendro_sites %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326)  # WGS84 lat/lon

# Bounding box and dynamic padding to zoom in ----------------------------------
bbox  <- st_bbox(dendro_sf)
x_pad <- as.numeric(bbox["xmax"] - bbox["xmin"]) * 0.15
y_pad <- as.numeric(bbox["ymax"] - bbox["ymin"]) * 0.15

# BASEMAP ######################################################################

world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
usa   <- world %>% filter(admin == "United States of America")

# VISUALIZATION ################################################################

p_dendro_struct <- ggplot() +
  # Base layer for geographic context
  geom_sf(data = usa, fill = "grey95", color = "grey80") +

  # Dendrometer trees:
  #   size = estimated current DBH
  #   fill = DBH increment (growth)
  geom_sf(
    data  = dendro_sf,
    aes(size = dbh_current_cm, fill = dbh_change_cm),
    shape = 21,
    color = "black",
    alpha = 0.9
  ) +

  # Zoom in tightly around the arboretum
  coord_sf(
    xlim   = c(bbox["xmin"] - x_pad, bbox["xmax"] + x_pad),
    ylim   = c(bbox["ymin"] - y_pad, bbox["ymax"] + y_pad),
    expand = FALSE
  ) +

  # North arrow & scale bar
  annotation_north_arrow(
    location    = "tr",
    which_north = "true",
    style       = north_arrow_fancy_orienteering
  ) +
  annotation_scale(
    location   = "bl",
    width_hint = 0.3
  ) +

  # Scales & labels
  scale_size_continuous(
    name  = "Current DBH (cm)",
    range = c(2, 10)
  ) +
  scale_fill_viridis_c(
    name   = "DBH increment (cm)",
    option = "C"
  ) +

  labs(
    title    = "Spatial pattern, size, and growth of trees in the Gifford Arboretum",
    subtitle = "Point size shows current DBH; color shows change in DBH since start of monitoring",
    caption  = "Data: dendrometer_clean (processed dendrometer dataset, Assignment 2).\nBasemap: Natural Earth. Projection: WGS84 (EPSG:4326)."
  ) +
  theme(
    legend.position  = "right",
    panel.grid.major = element_line(linewidth = 0.2),
    panel.background = element_rect(fill = "aliceblue"),
    panel.border     = element_rect(color = "black", fill = NA),
    aspect.ratio     = 1
  )

# Print to viewer --------------------------------------------------------------
p_dendro_struct

# EXPORT #######################################################################

ggsave(
  filename = here("results", "img", "gifford_dendrometer_structure_growth.png"),
  plot     = p_dendro_struct,
  width    = 7,
  height   = 6,
  dpi      = 300
)
