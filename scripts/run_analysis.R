# Main R workflow for the respiratory virus time-series project.

# This script runs the full analysis from raw data to saved outputs.
# All paths are project-root relative through here::here().

required_packages <- c(
  "tidyverse",
  "lubridate",
  "readxl",
  "forecast",
  "tseries",
  "vars",
  "lmtest",
  "ggplot2",
  "zoo",
  "here"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    function(package_name) {
      suppressMessages(
        suppressWarnings(requireNamespace(package_name, quietly = TRUE))
      )
    },
    logical(1)
  )
]

if (length(missing_packages) > 0) {
  stop(
    "Install missing R packages before running the analysis: ",
    paste(missing_packages, collapse = ", ")
  )
}

dir.create(here::here("data", "processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("reports"), recursive = TRUE, showWarnings = FALSE)

source(here::here("R", "preprocessing.R"))
source(here::here("R", "visualization.R"))
source(here::here("R", "evaluation.R"))
source(here::here("R", "modeling.R"))

cat("\nStarting R respiratory virus time-series analysis...\n")

lab_data <- load_laboratory_data()
inspection_summary <- inspect_laboratory_data(lab_data)

data_dictionary <- load_lab_data_dictionary()
summarize_lab_data_dictionary(data_dictionary)

target_column <- choose_target_variable(lab_data)
weekly_data <- build_weekly_lab_timeseries(
  lab_data = lab_data,
  target_column = target_column,
  selected_viruses = c("Influenza", "RSV", "SARS-CoV-2")
)

eda_plots <- create_eda_plots(
  weekly_long = weekly_data$long,
  weekly_wide = weekly_data$wide
)

adf_results <- run_adf_tests(weekly_data$wide)
model_comparison <- fit_arima_sarima_models(weekly_data$wide, test_size = 8)
var_results <- fit_var_model(weekly_data$wide, max_lag = 4)
granger_results <- run_granger_tests(weekly_data$wide, max_lag = 4)

cat("\nAnalysis complete.\n")
cat("Cleaned data saved to data/processed/.\n")
cat("Figures saved to figures/.\n")
cat("Tables saved to tables/.\n")
