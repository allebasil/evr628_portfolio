################################################################################
# Visualizing dendrometer data
################################################################################
# Izzie Childress
# EVR 628 - Assignment 3
# December 9, 2025
#
# This script loads processed dendrometer data, creates visualizations of
# radial growth over time and growth–temperature relationships, and exports
# figures as .png files for use in the final project.
################################################################################

# SET UP #######################################################################
library(tidyverse)
library(here)
library(cowplot)

theme_set(theme_bw(base_size = 12))

# Load processed data ----------------------------------------------------------
clean_data <- readr::read_rds(
  here("data", "processed", "dendrometer_clean.rds")
)

# PROCESSING ###################################################################
# Parse datetime (if not already POSIXct) and add date
clean_data <- clean_data |>
  mutate(
    datetime = as.POSIXct(
      datetime,
      format = "%Y.%m.%d %H:%M",   # change if your format differs
      tz = "America/New_York"
    ),
    date = as.Date(datetime)
  ) |>
  # Filter out obviously impossible air temperatures
  filter(
    air_temp_C >= 0,
    air_temp_C <= 45
  )

# Compute interval growth rates per sensor
data_rate <- clean_data |>
  arrange(sensor_id, datetime) |>
  group_by(sensor_id) |>
  mutate(
    radial_growth_diff_um = radial_growth_um - dplyr::lag(radial_growth_um),
    dt_hours              = as.numeric(
                              difftime(datetime,
                                       dplyr::lag(datetime),
                                       units = "hours")
                            ),
    growth_rate_um_per_h  = radial_growth_diff_um / dt_hours
  ) |>
  ungroup() |>
  # keep only sensible intervals
  filter(
    !is.na(growth_rate_um_per_h),
    dt_hours > 0,
    abs(growth_rate_um_per_h) <= 200   # drop wild spikes
  )

# VISUALIZE ####################################################################
## Plot 1: Time series of radial growth by sensor ------------------------------
p_time <- clean_data |>
  ggplot(aes(x = datetime,
             y = radial_growth_um,
             colour = sensor_id,
             group = sensor_id)) +
  geom_line(linewidth = 0.4) +
  labs(
    title   = "Radial growth over time by sensor",
    x       = "Date",
    y       = "Radial growth (µm)",
    colour  = "Sensor ID",
    caption = "Gifford Arboretum dendrometer data"
  ) +
  facet_wrap(~ sensor_id, scales = "free_y") +
  scale_x_datetime(
    date_breaks = "6 months", date_labels = "%b\n%y"
  ) +
  theme(
    legend.position = "none",
    plot.title      = element_text(face = "bold"),
    axis.text.x     = element_text(size = 6)
  )


## Plot 2A: Scatter of growth rate vs air temperature --------------------------
p_temp_scatter <- data_rate |>
  ggplot(aes(x = air_temp_C, y = growth_rate_um_per_h)) +
  geom_point(alpha = 0.3) +
  geom_smooth(se = TRUE, colour = "blue") +
  labs(
    title   = "Growth rate as a function of air temperature",
    x       = "Air temperature (°C)",
    y       = "Radial growth rate (µm/hour)",
    caption = "Points are intervals between successive logger readings"
  ) +
  theme(
    plot.title = element_text(face = "bold")
  )

## Plot 2B: Mean growth rate by temperature bin (no facets) --------------------
data_rate_binned <- data_rate |>
  mutate(
    temp_bin = cut(
      air_temp_C,
      breaks = seq(10, 40, by = 2)
    )
  ) |>
  filter(!is.na(temp_bin)) |>
  group_by(temp_bin) |>
  summarize(
    mean_rate = mean(growth_rate_um_per_h, na.rm = TRUE),
    .groups   = "drop"
  )

p_temp_binned <- ggplot(data_rate_binned,
                        aes(x = temp_bin, y = mean_rate)) +
  geom_col() +
  labs(
    title   = "Mean growth rate by air temperature bin",
    x       = "Air temperature bin (°C)",
    y       = "Mean radial growth rate (µm/hour)",
    caption = "Bars show average interval growth rate within each temperature bin"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title  = element_text(face = "bold")
  )

## Combine A & B into one panel -----------------------------------------------
growth_temp_panel <- plot_grid(
  p_temp_scatter,
  p_temp_binned,
  ncol   = 1,
  labels = c("A", "B")
)

# EXPORT #######################################################################
dir.create(here("results", "img"), recursive = TRUE, showWarnings = FALSE)

ggsave(
  filename = here("results", "img", "radial_growth_time_series.png"),
  plot     = p_time,
  width    = 8,
  height   = 6,
  dpi      = 300
)

ggsave(
  filename = here("results", "img", "growth_vs_temperature.png"),
  plot     = growth_temp_panel,
  width    = 8,
  height   = 8,
  dpi      = 300
)
