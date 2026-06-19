# Data

Place downloaded source files in `data/raw/`.

The main analysis should begin with the laboratory data CSV from the Canadian Respiratory Virus Surveillance / FluWatch+ data portal. The clinical data CSV and data dictionary XLSX can also be stored here, but clinical data should only be used later if it can be cleanly linked to the laboratory data.

Cleaned analysis-ready files should be written to `data/processed/`.

Raw and processed data files are ignored by Git by default because public redistribution may depend on file size, licensing, and data portal terms.
