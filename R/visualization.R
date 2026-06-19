# Visualization helpers for the R analysis pipeline.

# Save a ggplot object to the figures directory.
save_project_plot <- function(plot_object, file_name, width = 10, height = 6) {
  ggplot2::ggsave(
    filename = here::here("figures", file_name),
    plot = plot_object,
    width = width,
    height = height,
    dpi = 300
  )
}

# Plot weekly percent positivity or other selected target values by virus.
plot_weekly_time_series <- function(weekly_long) {
  plot_object <- weekly_long |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$week_ending_date,
        y = .data$target_value,
        color = .data$Virus
      )
    ) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 1.8) +
    ggplot2::labs(
      title = "Weekly Respiratory Virus Indicators",
      x = "Week ending date",
      y = unique(weekly_long$target_variable),
      color = "Virus"
    ) +
    ggplot2::theme_minimal()

  save_project_plot(plot_object, "weekly_time_series_by_virus.png")
  plot_object
}

# Plot average target value by epidemiological week.
plot_seasonal_pattern <- function(weekly_long) {
  seasonal_data <- weekly_long |>
    dplyr::group_by(.data$Virus, .data$epi_week) |>
    dplyr::summarise(
      average_value = mean(.data$target_value, na.rm = TRUE),
      .groups = "drop"
    )

  plot_object <- seasonal_data |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$epi_week,
        y = .data$average_value,
        color = .data$Virus
      )
    ) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 1.8) +
    ggplot2::labs(
      title = "Seasonal Pattern by Epidemiological Week",
      x = "Epidemiological week",
      y = "Average target value",
      color = "Virus"
    ) +
    ggplot2::theme_minimal()

  save_project_plot(plot_object, "seasonal_pattern_by_epi_week.png")
  plot_object
}

# Plot virus trends on a shared scale for visual comparison.
plot_virus_trend_comparison <- function(weekly_long) {
  plot_object <- weekly_long |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$week_ending_date,
        y = .data$target_value,
        color = .data$Virus
      )
    ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::facet_wrap(~Virus, scales = "free_y", ncol = 1) +
    ggplot2::labs(
      title = "Comparison of Virus Trends",
      x = "Week ending date",
      y = unique(weekly_long$target_variable),
      color = "Virus"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none")

  save_project_plot(plot_object, "comparison_of_virus_trends.png", height = 8)
  plot_object
}

# Plot missingness over time for the wide modeling dataset.
plot_missingness_over_time <- function(weekly_wide) {
  missing_data <- weekly_wide |>
    tidyr::pivot_longer(
      cols = -c(week_ending_date, epi_year, epi_week),
      names_to = "series",
      values_to = "value"
    ) |>
    dplyr::mutate(is_missing = is.na(.data$value))

  plot_object <- missing_data |>
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$week_ending_date,
        y = .data$series,
        fill = .data$is_missing
      )
    ) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_manual(values = c("FALSE" = "#2C7FB8", "TRUE" = "#D7191C")) +
    ggplot2::labs(
      title = "Missingness Over Time",
      x = "Week ending date",
      y = "Series",
      fill = "Missing"
    ) +
    ggplot2::theme_minimal()

  save_project_plot(plot_object, "missingness_over_time.png", height = 4)
  plot_object
}

# Create all exploratory plots used in the main workflow.
create_eda_plots <- function(weekly_long, weekly_wide) {
  list(
    weekly_time_series = plot_weekly_time_series(weekly_long),
    seasonal_pattern = plot_seasonal_pattern(weekly_long),
    trend_comparison = plot_virus_trend_comparison(weekly_long),
    missingness = plot_missingness_over_time(weekly_wide)
  )
}
