# Statistical Time Series Modeling of Canadian Respiratory Virus Surveillance Data

## Project Summary

This project analyzes Canadian respiratory virus surveillance laboratory data using R-based statistical time-series methods. The main dataset is the laboratory data CSV downloaded from the Canadian Respiratory Virus Surveillance / FluWatch+ data portal. The clinical data CSV and data dictionary XLSX may be used later for supplementary analysis, but the main workflow begins with the laboratory data.

The analysis focuses on weekly indicators for influenza, RSV, and COVID-19/SARS-CoV-2 when available. Percent positivity is used as the preferred modeling target. If percent positivity is not available in a future dataset, the workflow falls back to positive detections or test counts with a TODO note to verify the choice.

Important interpretation note: Granger causality results are labeled as predictive lead-lag associations only. They should not be interpreted as true biological or epidemiological causation.

## Research Questions

1. Do weekly respiratory virus indicators such as influenza, RSV, and COVID-19 show clear seasonal patterns?
2. Can SARIMA models improve short-term forecasting compared with non-seasonal ARIMA models?
3. Do past values of one virus indicator provide predictive information about another virus indicator using VAR models and Granger causality tests?
4. How do patterns and forecast accuracy differ across viruses and surveillance periods?

## Data Source

Data can be downloaded from the Government of Canada Health Infobase page:

- [Canadian respiratory virus surveillance report: Explore the data](https://health-infobase.canada.ca/respiratory-virus-surveillance/explore.html)

Use the page's **Download the data** section to download the laboratory data CSV, clinical data CSV, and data dictionary XLSX. The main analysis begins with the laboratory data file.

Place downloaded raw files in `data/raw/`.

Expected files:

- `Laboratory data - 2026-05-29.csv`
- `Clinical data - 2026-05-29.csv`
- `Data_Dictionary.xlsx`

Raw data files may need to be downloaded separately depending on file size, licensing, and data portal terms. Raw data are ignored by Git by default.

The source page notes that these surveillance data may change retrospectively because of reporting delays and updates. For reproducibility, record the download date and keep the downloaded file names unchanged when running this project.

## R Packages

The workflow uses:

- `tidyverse`
- `lubridate`
- `readxl`
- `janitor`
- `forecast`
- `tseries`
- `vars`
- `lmtest`
- `ggplot2`
- `zoo`
- `here`

Install missing packages in R with:

```r
install.packages(c(
  "tidyverse", "lubridate", "readxl", "janitor", "forecast",
  "tseries", "vars", "lmtest", "ggplot2", "zoo", "here"
))
```

## Analysis Workflow

Run the full workflow from the project root:

```bash
Rscript scripts/run_analysis.R
```

The script:

1. Loads the laboratory CSV from `data/raw/`.
2. Inspects column names, missing values, date/week variables, geography variables, and virus variables.
3. Reads the laboratory data dictionary from the XLSX workbook.
4. Selects the target variable, preferring `Percent of tests positive`.
5. Builds weekly time-series datasets for influenza, RSV, and SARS-CoV-2.
6. Saves cleaned data to `data/processed/`.
7. Creates EDA plots in `figures/`.
8. Runs ADF stationarity checks.
9. Fits ARIMA and SARIMA models with `forecast::auto.arima()`.
10. Uses a chronological train/test split.
11. Compares forecasts using MAE and RMSE.
12. Fits a VAR model with `vars` when the data support it.
13. Runs Granger predictive lead-lag tests with `lmtest`.
14. Saves model comparison and Granger results to `tables/`.

## Code Organization

The project uses a modular R structure so the analysis is easier to read, test, and revise.

- `scripts/run_analysis.R` is the main script. It loads packages, creates output folders, sources the helper files, and runs the full workflow from raw data to saved outputs.
- `R/preprocessing.R` contains functions for loading the laboratory data, reading the data dictionary, inspecting variables, choosing the target variable, and building cleaned weekly datasets.
- `R/visualization.R` contains functions for creating EDA plots with `ggplot2` and saving them to `figures/`.
- `R/modeling.R` contains functions for ADF tests, ARIMA/SARIMA modeling with `forecast::auto.arima()`, VAR modeling, and Granger predictive lead-lag tests.
- `R/evaluation.R` contains helper functions for chronological train/test splitting and forecast accuracy metrics such as MAE and RMSE.

The helper files are sourced by `scripts/run_analysis.R`, so users only need to run one command:

```bash
Rscript scripts/run_analysis.R
```

## Repository Structure

```text
canadian-respiratory-virus-time-series/
|-- README.md
|-- .gitignore
|-- data/
|   |-- raw/
|   `-- processed/
|-- R/
|   |-- preprocessing.R
|   |-- visualization.R
|   |-- modeling.R
|   `-- evaluation.R
|-- scripts/
|   `-- run_analysis.R
|-- figures/
|-- tables/
`-- reports/
```

## Planned Outputs

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
- `tables/var_results.csv`
- `tables/granger_results.csv`

## Preliminary Findings Placeholder

TODO: Review the generated figures and tables, then summarize observed seasonal patterns, forecast accuracy differences, and predictive lead-lag associations. Avoid unsupported biological causal interpretations.

## Reproducibility Notes

All analysis paths are relative to the project root through `here::here()`. The workflow should continue to work if the repository folder is moved to another location.

The final written report is not generated automatically by the code. It can be written separately after reviewing the figures and tables produced by the analysis pipeline.
