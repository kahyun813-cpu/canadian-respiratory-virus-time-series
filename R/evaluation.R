# Forecast evaluation helpers.

# Split a time series into chronological train and test pieces.
time_series_train_test_split <- function(values, test_size = 8) {
  values <- stats::na.omit(as.numeric(values))

  if (length(values) <= test_size) {
    stop("Not enough observations for the requested test size.")
  }

  train <- values[seq_len(length(values) - test_size)]
  test <- values[(length(values) - test_size + 1):length(values)]

  list(train = train, test = test)
}

# Calculate MAE and RMSE.
calculate_forecast_metrics <- function(actual, predicted) {
  actual <- as.numeric(actual)
  predicted <- as.numeric(predicted)

  if (length(actual) != length(predicted)) {
    stop("actual and predicted must have the same length.")
  }

  tibble::tibble(
    mae = mean(abs(actual - predicted), na.rm = TRUE),
    rmse = sqrt(mean((actual - predicted)^2, na.rm = TRUE))
  )
}

# Save a model comparison table to tables/.
save_model_comparison <- function(model_comparison) {
  readr::write_csv(
    model_comparison,
    here::here("tables", "model_comparison.csv")
  )
}
