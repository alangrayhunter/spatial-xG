# Spatially Enhanced xG: Does Freeze-Frame Context Improve Shot Outcome Prediction in Football?

STA Honours project, Department of Statistical Sciences, University of Cape Town (2026).
Rejoice Mhuru and Alan Hunter. Supervisor: Neil Watson.

Data: StatsBomb Open Data (Hudl StatsBomb), accessed with the StatsBombR package. The data is not stored
in this repository; the pipeline downloads it.

## Set up a new computer

1. Install R, RStudio and Quarto.
2. Clone this repository (GitHub Desktop: File > Clone repository > URL).
3. Open `spatial-xG.Rproj` and run `source("setup.R")` once (installs the packages and LaTeX).

## Render the dissertation (PDF)

In the RStudio Terminal, from the project folder:

    quarto render --to pdf

The PDF is `_book/MHRREJ002_HNTALA001_Honours_FinalHandIn_2026.pdf`.

The book only loads results. The first chunk of `index.qmd` checks the pipeline outputs: if any are missing,
it runs that pipeline file and every one after it (p1 to p5), then carries on. If everything exists, nothing
in the pipeline runs. A fresh clone has no `data/`, so the first render runs the whole pipeline
(several hours). To rebuild every result from scratch, also delete `outputs/` before rendering.

## The pipeline (`_pipeline/`)

| File | Makes | Time |
|---|---|---|
| p1_import.qmd | data/Comp_Match_Data.RData, data/raw_events/ | about an hour |
| p2_data.qmd | data/key_passes_raw, extra_events, shots_comp_info, shots_cleaned, shots_final | minutes |
| p3_features.qmd | data/shots_model.rds, outputs/feature_sets.rds, outputs/feature_groups.rds | minutes |
| p4_models.qmd | outputs/match_split, xgb_tuning, logistic_coefs, xgb_gain, permutation_importance; data/predictions, shap | hours (tuning) |
| p5_results.qmd | every other file in outputs/ | about a minute |

Each file always runs in full when run. To run one by hand (for example after editing p5):

    quarto render _pipeline/p5_results.qmd

Then re-run the files after it if their inputs changed.

## Where things are

- Front matter (abstract, acknowledgements, declaration of AI use, contents): `index.qmd`. Title page and plagiarism declaration: `_tex/before-body.tex` and `images/`.
- Chapters: `01-introduction.qmd` to `07-conclusion.qmd`.
- Shared settings, names, colours and helper functions: `_common.R`.
- References: `references.bib` (cite as `[@key]`), styled by `harvard-university-of-cape-town.csl`.
- Nothing is saved by the book. `data/` stays off GitHub; `outputs/` (small) is on GitHub.
