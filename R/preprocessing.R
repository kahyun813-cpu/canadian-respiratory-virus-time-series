# Data loading and preprocessing helpers for the R analysis pipeline.

# Load the laboratory CSV from data/raw.
load_laboratory_data <- function(file_name = "Laboratory data - 2026-05-29.csv") {
  file_path <- here::here("data", "raw", file_name)

  if (!file.exists(file_path)) {
    stop("Laboratory data file not found: ", file_path)
  }

  readr::read_csv(file_path, show_col_types = FALSE)
}

# Load the laboratory sheet from the data dictionary workbook.
load_lab_data_dictionary <- function(file_name = "Data_Dictionary.xlsx") {
  file_path <- here::here("data", "raw", file_name)

  if (!file.exists(file_path)) {
    stop("Data dictionary file not found: ", file_path)
  }

  readxl::read_excel(file_path, sheet = "DataDictionary_labdata")
}

# Print a beginner-readable inspection of the raw laboratory data.
inspect_laboratory_data <- function(lab_data) {
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("Laboratory Data Inspection\n")
  cat(strrep("=", 80), "\n", sep = "")

  cat("Shape:", nrow(lab_data), "rows x", ncol(lab_data), "columns\n\n")

  cat("Column names:\n")
  print(names(lab_data))

  cat("\nFirst few rows:\n")
  print(utils::head(lab_data))

  cat("\nMissing value summary:\n")
  missing_summary <- tibble::tibble(
    column = names(lab_data),
    missing = purrr::map_int(lab_data, ~ sum(is.na(.x))),
    n_unique = purrr::map_int(lab_data, ~ dplyr::n_distinct(.x, na.rm = TRUE))
  )
  print(missing_summary)

  key_columns <- names(lab_data)[
    stringr::str_detect(
      stringr::str_to_lower(names(lab_data)),
      "virus|jurisdiction|province|region|year|week|date"
    )
  ]

  cat("\nUnique values for virus, geography, and date/week columns:\n")
  for (column_name in key_columns) {
    cat("\n", column_name, ":\n", sep = "")
    print(unique(lab_data[[column_name]]))
  }

  invisible(missing_summary)
}

# Print and save the data dictionary summary.
summarize_lab_data_dictionary <- function(data_dictionary) {
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("Laboratory Data Dictionary\n")
  cat(strrep("=", 80), "\n", sep = "")
  print(data_dictionary)

  readr::write_csv(
    data_dictionary,
    here::here("tables", "data_dictionary_lab_summary.csv")
  )

  invisible(data_dictionary)
}

# Choose the target variable for modeling.
choose_target_variable <- function(lab_data) {
  preferred_columns <- c(
    "Percent of tests positive",
    "Detections",
    "Tests"
  )

  for (column_name in preferred_columns) {
    if (column_name %in% names(lab_data)) {
      cat("\nSelected target variable:", column_name, "\n")

      if (column_name != "Percent of tests positive") {
        cat("TODO: Verify this fallback target using the data dictionary.\n")
      }

      return(column_name)
    }
  }

  stop("No supported target variable found.")
}

# Build cleaned long and wide weekly datasets for selected viruses.
build_weekly_lab_timeseries <- function(
    lab_data,
    target_column,
    selected_viruses = c("Influenza", "RSV", "SARS-CoV-2")) {

  required_columns <- c(
    "Jurisdiction",
    "Surveillance year",
    "Surveillance week",
    "Week ending date",
    "Year_Week",
    "Virus",
    "Tests",
    "Detections",
    target_column
  )

  missing_columns <- setdiff(required_columns, names(lab_data))
  if (length(missing_columns) > 0) {
    stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
  }

  virus_name_lookup <- c(
    "Influenza" = "influenza_percent_positive",
    "RSV" = "rsv_percent_positive",
    "SARS-CoV-2" = "covid19_percent_positive"
  )

  weekly_long <- lab_data |>
    dplyr::filter(.data$Virus %in% selected_viruses) |>
    dplyr::mutate(
      week_ending_date = lubridate::ymd(.data$`Week ending date`),
      epi_year = as.integer(.data$`Surveillance year`),
      epi_week = as.integer(.data$`Surveillance week`),
      target_variable = target_column,
      target_value = as.numeric(.data[[target_column]]),
      tests = as.numeric(.data$Tests),
      detections = as.numeric(.data$Detections),
      virus_model_name = unname(virus_name_lookup[.data$Virus])
    ) |>
    dplyr::select(
      Jurisdiction,
      epi_year,
      epi_week,
      week_ending_date,
      `Year_Week`,
      Virus,
      virus_model_name,
      tests,
      detections,
      target_variable,
      target_value
    ) |>
    dplyr::arrange(.data$week_ending_date, .data$Virus)

  weekly_wide <- weekly_long |>
    dplyr::select(
      week_ending_date,
      epi_year,
      epi_week,
      virus_model_name,
      target_value
    ) |>
    tidyr::pivot_wider(
      names_from = virus_model_name,
      values_from = target_value
    ) |>
    dplyr::arrange(.data$week_ending_date)

  readr::write_csv(
    weekly_long,
    here::here("data", "processed", "cleaned_weekly_lab_long.csv")
  )
  readr::write_csv(
    weekly_wide,
    here::here("data", "processed", "cleaned_weekly_lab_wide.csv")
  )

  list(long = weekly_long, wide = weekly_wide)
}
