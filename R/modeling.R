# Statistical modeling helpers.

# Run an Augmented Dickey-Fuller stationarity test for each virus series.
run_adf_tests <- function(weekly_wide) {
  model_columns <- setdiff(
    names(weekly_wide),
    c("week_ending_date", "epi_year", "epi_week")
  )

  results <- purrr::map_dfr(model_columns, function(column_name) {
    values <- stats::na.omit(as.numeric(weekly_wide[[column_name]]))

    tryCatch(
      {
        test_result <- tseries::adf.test(values)
        tibble::tibble(
          series = column_name,
          adf_statistic = unname(test_result$statistic),
          p_value = test_result$p.value,
          method = test_result$method,
          error = NA_character_
        )
      },
      error = function(e) {
        tibble::tibble(
          series = column_name,
          adf_statistic = NA_real_,
          p_value = NA_real_,
          method = "ADF test",
          error = conditionMessage(e)
        )
      }
    )
  })

  readr::write_csv(results, here::here("tables", "adf_results.csv"))
  results
}

# Fit ARIMA and SARIMA models with forecast::auto.arima().
fit_arima_sarima_models <- function(weekly_wide, test_size = 8) {
  model_columns <- setdiff(
    names(weekly_wide),
    c("week_ending_date", "epi_year", "epi_week")
  )

  results <- purrr::map_dfr(model_columns, function(column_name) {
    split <- time_series_train_test_split(weekly_wide[[column_name]], test_size)

    train_ts <- stats::ts(split$train, frequency = 52)
    test_values <- split$test

    model_specs <- list(
      ARIMA = list(seasonal = FALSE),
      SARIMA = list(seasonal = TRUE)
    )

    purrr::imap_dfr(model_specs, function(spec, model_name) {
      tryCatch(
        {
          fitted_model <- forecast::auto.arima(
            train_ts,
            seasonal = spec$seasonal,
            stepwise = FALSE,
            approximation = FALSE
          )

          forecast_values <- forecast::forecast(
            fitted_model,
            h = length(test_values)
          )$mean

          metrics <- calculate_forecast_metrics(test_values, forecast_values)

          tibble::tibble(
            series = column_name,
            model = model_name,
            arima_order = paste(forecast::arimaorder(fitted_model), collapse = ","),
            n_train = length(split$train),
            n_test = length(split$test),
            mae = metrics$mae,
            rmse = metrics$rmse,
            error = NA_character_
          )
        },
        error = function(e) {
          tibble::tibble(
            series = column_name,
            model = model_name,
            arima_order = NA_character_,
            n_train = length(split$train),
            n_test = length(split$test),
            mae = NA_real_,
            rmse = NA_real_,
            error = conditionMessage(e)
          )
        }
      )
    })
  }) |>
    dplyr::arrange(.data$rmse, .data$mae)

  save_model_comparison(results)
  results
}

# Run Ljung-Box residual diagnostics for fitted ARIMA/SARIMA models.
run_residual_diagnostics <- function(weekly_wide, ljung_box_lag = 10) {
  model_columns <- setdiff(
    names(weekly_wide),
    c("week_ending_date", "epi_year", "epi_week")
  )

  results <- purrr::map_dfr(model_columns, function(column_name) {
    values <- stats::na.omit(as.numeric(weekly_wide[[column_name]]))
    full_ts <- stats::ts(values, frequency = 52)

    model_specs <- list(
      ARIMA = list(seasonal = FALSE),
      SARIMA = list(seasonal = TRUE)
    )

    purrr::imap_dfr(model_specs, function(spec, model_name) {
      tryCatch(
        {
          fitted_model <- forecast::auto.arima(
            full_ts,
            seasonal = spec$seasonal,
            stepwise = FALSE,
            approximation = FALSE
          )

          residuals <- stats::na.omit(as.numeric(stats::residuals(fitted_model)))
          test_lag <- min(ljung_box_lag, length(residuals) - 1)
          fit_df <- min(length(stats::coef(fitted_model)), test_lag - 1)

          test_result <- stats::Box.test(
            residuals,
            lag = test_lag,
            type = "Ljung-Box",
            fitdf = fit_df
          )

          tibble::tibble(
            series = column_name,
            model = model_name,
            arima_order = paste(forecast::arimaorder(fitted_model), collapse = ","),
            diagnostic_test = "Ljung-Box test",
            lag = test_lag,
            fit_df = fit_df,
            statistic = unname(test_result$statistic),
            p_value = test_result$p.value,
            null_hypothesis = "Model residuals are independently distributed with no remaining autocorrelation.",
            interpretation = dplyr::if_else(
              test_result$p.value < 0.05,
              "Reject H0: residual autocorrelation may remain.",
              "Fail to reject H0: no strong evidence of residual autocorrelation."
            ),
            error = NA_character_
          )
        },
        error = function(e) {
          tibble::tibble(
            series = column_name,
            model = model_name,
            arima_order = NA_character_,
            diagnostic_test = "Ljung-Box test",
            lag = NA_integer_,
            fit_df = NA_integer_,
            statistic = NA_real_,
            p_value = NA_real_,
            null_hypothesis = "Model residuals are independently distributed with no remaining autocorrelation.",
            interpretation = NA_character_,
            error = conditionMessage(e)
          )
        }
      )
    })
  })

  readr::write_csv(results, here::here("tables", "residual_diagnostics.csv"))
  results
}

# Fit a VAR model if enough complete multivariate observations are available.
fit_var_model <- function(weekly_wide, max_lag = 4) {
  model_columns <- setdiff(
    names(weekly_wide),
    c("week_ending_date", "epi_year", "epi_week")
  )

  model_data <- weekly_wide |>
    dplyr::select(dplyr::all_of(model_columns)) |>
    tidyr::drop_na()

  if (nrow(model_data) < 20 || length(model_columns) < 2) {
    result <- tibble::tibble(
      model = "VAR",
      selected_lag = NA_integer_,
      aic = NA_real_,
      error = "Not enough complete observations or series for VAR."
    )
    readr::write_csv(result, here::here("tables", "var_results.csv"))
    return(list(model = NULL, summary = result))
  }

  tryCatch(
    {
      lag_selection <- vars::VARselect(model_data, lag.max = max_lag, type = "const")
      selected_lag <- as.integer(lag_selection$selection[["AIC(n)"]])
      selected_lag <- max(1, selected_lag)

      fitted_var <- vars::VAR(model_data, p = selected_lag, type = "const")

      result <- tibble::tibble(
        model = "VAR",
        selected_lag = selected_lag,
        aic = stats::AIC(fitted_var),
        error = NA_character_
      )

      readr::write_csv(result, here::here("tables", "var_results.csv"))
      list(model = fitted_var, summary = result)
    },
    error = function(e) {
      result <- tibble::tibble(
        model = "VAR",
        selected_lag = NA_integer_,
        aic = NA_real_,
        error = conditionMessage(e)
      )
      readr::write_csv(result, here::here("tables", "var_results.csv"))
      list(model = NULL, summary = result)
    }
  )
}

# Run pairwise Granger tests as predictive lead-lag association tests.
run_granger_tests <- function(weekly_wide, max_lag = 4) {
  model_columns <- setdiff(
    names(weekly_wide),
    c("week_ending_date", "epi_year", "epi_week")
  )

  pairs <- tidyr::expand_grid(
    caused = model_columns,
    causing = model_columns
  ) |>
    dplyr::filter(.data$caused != .data$causing)

  results <- purrr::pmap_dfr(pairs, function(caused, causing) {
    purrr::map_dfr(seq_len(max_lag), function(lag_value) {
      test_data <- weekly_wide |>
        dplyr::select(
          caused_value = dplyr::all_of(caused),
          causing_value = dplyr::all_of(causing)
        ) |>
        tidyr::drop_na()

      tryCatch(
        {
          # lmtest::grangertest evaluates whether lags of causing_value help
          # predict caused_value. This is not evidence of biological causation.
          test_result <- lmtest::grangertest(
            caused_value ~ causing_value,
            order = lag_value,
            data = test_data
          )

          tibble::tibble(
            caused = caused,
            causing = causing,
            lag = lag_value,
            f_statistic = as.numeric(test_result$F[2]),
            p_value = as.numeric(test_result$`Pr(>F)`[2]),
            interpretation_note = "Predictive lead-lag association only; not evidence of biological causation.",
            error = NA_character_
          )
        },
        error = function(e) {
          tibble::tibble(
            caused = caused,
            causing = causing,
            lag = lag_value,
            f_statistic = NA_real_,
            p_value = NA_real_,
            interpretation_note = "Predictive lead-lag association only; not evidence of biological causation.",
            error = conditionMessage(e)
          )
        }
      )
    })
  })

  readr::write_csv(results, here::here("tables", "granger_results.csv"))
  results
}
