# setup.R: run once on any new computer.
# Safe to re-run: it only installs what's missing.

# 1. CRAN packages
cran_packages <- c("tidyverse", "here", "knitr", "rmarkdown", "quarto", "scales",
                   "skimr", "ggsoccer", "broom", "pROC", "xgboost", "remotes", "tinytex",
                   "ggrepel", "withr", "kableExtra")

missing <- setdiff(cran_packages, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

# 2. GitHub-only packages
github_packages <- c(StatsBombR   = "statsbomb/StatsBombR")
for (pkg in names(github_packages)) {
  if (!requireNamespace(pkg, quietly = TRUE)) remotes::install_github(github_packages[[pkg]])
}

# 3. Quarto itself (a separate program, not an R package)
has_quarto <- tryCatch(!is.null(quarto::quarto_path()), error = \(e) FALSE)
if (!has_quarto) stop("Install Quarto from https://quarto.org, restart RStudio, then run this again.")

# 4. LaTeX, for the PDF
if (!tinytex::is_tinytex()) tinytex::install_tinytex()
tinytex::tlmgr_install(c("amsfonts", "amsmath", "atbegshi", "atveryend", "auxhook", "bigintcalc", "bitset",
                         "bookmark", "booktabs", "caption", "colortbl", "environ", "eso-pic", "etoolbox", "float", "fontspec",
                         "footmisc", "footnotehyper", "geometry", "gettitlestring", "graphics", "graphics-cfg", "graphics-def",
                         "hycolor", "hyperref", "iftex", "infwarerr", "intcalc", "koma-script", "kvdefinekeys", "kvoptions",
                         "kvsetkeys", "l3kernel", "l3packages", "ltablex", "ltxcmds", "makecell", "microtype",
                         "multirow", "pdfescape", "pdflscape", "pdfpages", "pdftexcmds", "refcount", "rerunfilecheck",
                         "stringenc", "tabu", "threeparttable", "threeparttablex", "tools", "trimspaces", "ulem", "unicode-math",
                         "uniquecounter", "upquote", "url", "varwidth", "wrapfig", "xcolor", "xltabular", "xurl"))

# 5. Print versions, so we can compare computers
R.version.string
sapply(c(cran_packages, names(github_packages)), \(p) as.character(packageVersion(p)))