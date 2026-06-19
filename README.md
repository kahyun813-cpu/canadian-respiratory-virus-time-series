# Statistical Time Series Modeling of Canadian Respiratory Virus Surveillance Data

R project for analyzing Canadian respiratory virus laboratory surveillance data with statistical time-series methods.

## Data

Download the data from:

- [Canadian respiratory virus surveillance report: Explore the data](https://health-infobase.canada.ca/respiratory-virus-surveillance/explore.html)

Place the downloaded files in `data/raw/`:

- `Laboratory data - 2026-05-29.csv`
- `Clinical data - 2026-05-29.csv`
- `Data_Dictionary.xlsx`

The main workflow uses the laboratory data. Raw data files are not committed to GitHub.

## Run

Install required R packages:

```r
install.packages(c(
  "tidyverse", "lubridate", "readxl", "forecast", "tseries",
  "vars", "lmtest", "ggplot2", "zoo", "here"
))
```

Run the analysis from the project root:

```bash
Rscript scripts/run_analysis.R
```

On this Windows machine, `Rscript` may need the full path:

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts\run_analysis.R
```

## Code

- `scripts/run_analysis.R`: main script that runs the full workflow
- `R/preprocessing.R`: load, inspect, and clean data
- `R/visualization.R`: create EDA plots
- `R/modeling.R`: ADF tests, ARIMA/SARIMA, Ljung-Box residual diagnostics, VAR, Granger tests
- `R/evaluation.R`: train/test split and MAE/RMSE helpers

## Outputs

Running `scripts/run_analysis.R` creates:

Cleaned data:

- `data/processed/cleaned_weekly_lab_long.csv`
- `data/processed/cleaned_weekly_lab_wide.csv`

Figures:

- `figures/weekly_time_series_by_virus.png`
- `figures/seasonal_pattern_by_epi_week.png`
- `figures/comparison_of_virus_trends.png`
- `figures/missingness_over_time.png`

Tables:

- `tables/data_dictionary_lab_summary.csv`
- `tables/adf_results.csv`
- `tables/model_comparison.csv`
- `tables/residual_diagnostics.csv`
- `tables/var_results.csv`
- `tables/granger_results.csv`

## Notes

The target variable is percent positivity when available. The Ljung-Box test checks whether ARIMA/SARIMA residual autocorrelation remains. Granger causality results are interpreted only as predictive lead-lag associations, not biological causation.

The written report is prepared separately after reviewing the generated figures and tables.
