# Data

Place downloaded source files in `data/raw/`.

Download the data from the Government of Canada Health Infobase page:

- [Canadian respiratory virus surveillance report: Explore the data](https://health-infobase.canada.ca/respiratory-virus-surveillance/explore.html)

Use the **Download the data** section to download:

- laboratory data CSV
- clinical data CSV
- data dictionary XLSX

The main analysis begins with the laboratory data CSV. The clinical data CSV can be stored here, but it should only be used later if it can be cleanly linked to the laboratory data.

Expected raw files for the current workflow:

- `Laboratory data - 2026-05-29.csv`
- `Clinical data - 2026-05-29.csv`
- `Data_Dictionary.xlsx`

Cleaned analysis-ready files should be written to `data/processed/`.

Raw and processed data files are ignored by Git by default because public redistribution may depend on file size, licensing, and data portal terms.

For reproducibility, keep a note of the data download date and source page URL when writing the final report.
