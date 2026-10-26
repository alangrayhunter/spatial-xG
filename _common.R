# _common.R: loaded at the top of every chapter. Only loads and draws, never saves anything.

library(tidyverse)
library(here)
library(ggrepel)
library(ggsoccer)

knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE,
                      fig.width = 6.5, fig.height = 4.5, dpi = 300, out.width = "100%")
options(knitr.kable.NA = "")

# bigger, black text everywhere (Neil 20 and 25 Oct)
theme_set(theme_minimal(base_size = 13) +
            theme(text = element_text(colour = "black"),
                  axis.text = element_text(colour = "black"),
                  strip.text = element_text(colour = "black", face = "bold"),
                  legend.position = "bottom"))

out <- function(name) readRDS(here("outputs", paste0(name, ".rds")))
dat <- function(name) readRDS(here("data", paste0(name, ".rds")))

# ---- names ----
tier_short <- c(std = "M1", std_ff = "M2", std_ctx = "M3", std_ctx_ff = "M4", full = "M5")
tier_full <- c(std = "M1 Baseline", std_ff = "M2 Spatial", std_ctx = "M3 Extended Baseline",
               std_ctx_ff = "M4 Extended Baseline + Spatial", full = "M5 Extended Spatial")
algo_short <- c(logistic = "LR", xgboost = "XGB", statsbomb = "")

# "M2 XGB", "M4 LR", "StatsBomb"
short_name <- function(model, tier) {
  if_else(model == "statsbomb", "StatsBomb", paste(tier_short[tier], algo_short[model]))
}

# "logistic_std_ff" -> model and tier
model_of <- function(id) if_else(id == "statsbomb", "statsbomb", str_extract(id, "^[a-z]+"))
tier_of <- function(id) if_else(id == "statsbomb", "statsbomb", str_remove(id, "^[a-z]+_"))

# ---- colours (Okabe-Ito, colour-blind safe) ----
m_colours <- c(M1 = "#56B4E9", M2 = "#0072B2", M3 = "#009E73", M4 = "#CC79A7", M5 = "#000000",
               StatsBomb = "#D55E00")
type_shapes <- c(`Logistic regression (LR)` = 16, `XGBoost (XGB)` = 17, `StatsBomb` = 18)
group_colours <- c(Baseline = "grey70", Spatial = "#0072B2",
                   `Extended Baseline` = "#E69F00", `Extended Spatial` = "#009E73")
zone_colours <- c(`Inside the box` = "#0072B2", `Outside the box` = "#E69F00")

# ---- formatting ----
fmt_p <- function(p) if_else(p < 0.001, "<\u00a00.001", as.character(signif(p, 2))) # no line break after <
fmt_num <- function(x, d = 4) formatC(x, format = "f", digits = d)

# blank out repeated labels in a grouped table column
blank_repeats <- function(x) if_else(x == lag(x, default = ""), "", x)

# ---- tables (LaTeX, booktabs) ----
# escape LaTeX special characters in table text
latex_escape <- function(x) {
  x <- gsub("([&%$#_{}])", "\\\\\\1", x)
  x <- gsub("~", "\\textasciitilde{}", x, fixed = TRUE)
  x <- gsub("^", "\\textasciicircum{}", x, fixed = TRUE)
  x <- gsub("\u00a0", "~", x, fixed = TRUE)
  x <- gsub("\u2264", "$\\le$", x, fixed = TRUE)
  x <- gsub("\u2265", "$\\ge$", x, fixed = TRUE)
  x
}

# long column headers go over two lines (split at the space nearest the middle)
wrap_header <- function(x) {
  vapply(x, \(h) {
    sp <- gregexpr(" ", h)[[1]]
    if (nchar(h) <= 9 || sp[1] < 0) return(h)
    cut <- sp[which.min(abs(sp - nchar(h) / 2))]
    paste0(substr(h, 1, cut - 1), "\n", substr(h, cut + 1, nchar(h)))
  }, character(1), USE.NAMES = FALSE)
}

# text columns left, number columns right. Tables that fit on a page don't split across pages;
# long ones (longtable) repeat their header. Rows are shaded alternately, or, for grouped tables,
# `group` puts each group under its own heading and `lines_by` draws a line where that column changes.
kable_tbl <- function(data, ..., col.names = names(data), group = NULL, lines_by = NULL,
                      longtable = nrow(data) > 24, note = NULL, size = NULL) {
  data <- as.data.frame(data, check.names = FALSE)
  names(data) <- col.names
  fill <- function(v) { v <- as.character(v); for (i in seq_along(v)[-1]) if (is.na(v[i]) || v[i] == "") v[i] <- v[i - 1]; v }
  if (!is.null(group)) {
    g <- fill(data[[group]])
    data[[group]] <- NULL
  }
  lines_at <- integer(0)
  if (!is.null(lines_by)) {
    v <- fill(data[[lines_by]])
    lines_at <- which(v[-1] != v[-length(v)])
    if (!is.null(group)) lines_at <- setdiff(lines_at, which(g[-1] != g[-length(g)]))
  }
  is_num <- vapply(data, is.numeric, logical(1))
  # numbers stored as text (p-values like "< 0.001", "1.1") are right-aligned too
  num_like <- vapply(data, \(x) {
    if (is.numeric(x)) return(TRUE)
    x <- trimws(gsub("\u00a0", " ", as.character(x)))
    x <- x[!is.na(x) & x != "" & x != "\u2013"]
    length(x) > 0 && all(grepl("^[<>]?\\s*[-\u2212]?[0-9][0-9.,]*%?$", x))
  }, logical(1))
  data[!is_num] <- lapply(data[!is_num], \(x) latex_escape(as.character(x)))
  heads <- kableExtra::linebreak(latex_escape(wrap_header(names(data))), align = "c")
  wide <- ncol(data) > 7
  t <- kableExtra::kbl(data, format = "latex", booktabs = TRUE, longtable = longtable, linesep = "",
                       escape = FALSE, align = ifelse(num_like, "r", "l"), col.names = heads, ...)
  opts <- c(if (longtable) "repeat_header" else "HOLD_position", if (!longtable && wide) "scale_down",
            if (is.null(group) && is.null(lines_by)) "striped")
  t <- kableExtra::kable_styling(t, latex_options = opts, stripe_color = "gray!8",
                                 font_size = if (!is.null(size)) size else if (longtable && wide) 9 else NULL)
  if (!is.null(group)) {
    runs <- rle(g)
    ends <- cumsum(runs$lengths)
    for (k in seq_along(runs$values)) {
      if (runs$values[k] == "") next   # rows with no group (e.g. the intercept) get no heading
      t <- kableExtra::pack_rows(t, latex_escape(runs$values[k]), ends[k] - runs$lengths[k] + 1, ends[k],
                                 escape = FALSE)
    }
  }
  for (i in lines_at) t <- kableExtra::row_spec(t, i, extra_latex_after = "\\midrule")
  if (!is.null(note)) t <- kableExtra::footnote(t, general = note, general_title = "Note:", threeparttable = TRUE)
  # row_spec leaves "\midrule\\" (an empty row under each line), remove the extra "\\"
  a <- attributes(t)
  t <- gsub("\\midrule\\\\\n", "\\midrule\n", t, fixed = TRUE)
  attributes(t) <- a
  t
}

# test-set metrics for every model, with plot labels
test_metrics <- function() {
  out("metrics") |>
    filter(set == "test") |>
    mutate(m = if_else(model == "statsbomb", "StatsBomb", tier_short[tier]),
           name = short_name(model, tier),
           type = case_when(model == "statsbomb" ~ "StatsBomb",
                            model == "xgboost" ~ "XGBoost (XGB)",
                            TRUE ~ "Logistic regression (LR)"))
}

# % improvement on every metric from one XGBoost model to another (Brier and log loss: % reduction)
lower_better <- c("Brier", "Log loss")
metric_improvement <- function(from, to, model_type = "xgboost") {
  goal_cut <- out("class_metrics") |> pull(cutoff) |> unique() |> setdiff(0.5)
  prob <- out("metrics") |>
    filter(set == "test", model == model_type) |>
    select(tier, AUROC = auc, `PR-AUC` = pr_auc, Brier = brier, `Log loss` = log_loss) |>
    pivot_longer(-tier, names_to = "metric")
  cls <- out("class_metrics") |>
    filter(model == model_type, cutoff == goal_cut) |>
    select(tier, Accuracy = accuracy, `Balanced accuracy` = balanced_accuracy, Recall = recall,
           Specificity = specificity, Precision = precision, F1 = f1) |>
    pivot_longer(-tier, names_to = "metric")
  bind_rows(prob |> mutate(type = "Probability and ranking"),
            cls |> mutate(type = "Classification (cut-off = training goal rate)")) |>
    filter(tier %in% c(from, to)) |>
    pivot_wider(names_from = tier, values_from = value) |>
    rename(a = all_of(from), b = all_of(to)) |>
    mutate(improvement = if_else(metric %in% lower_better, 1 - b / a, b / a - 1) * 100,
           type = fct_relevel(type, "Probability and ranking"))
}

improvement_plot <- function(d, x_label) {
  d |>
    mutate(just = if_else(improvement < 0, 1.15, -0.15)) |>
    ggplot(aes(improvement, fct_reorder(metric, improvement))) +
    geom_col(fill = "#0072B2") +
    geom_text(aes(label = sprintf("%.1f%%", improvement), hjust = just), size = 4) +
    geom_vline(xintercept = 0) +
    facet_wrap(~ type, ncol = 1, scales = "free_y") +
    scale_x_continuous(expand = expansion(mult = 0.2)) +
    labs(x = x_label, y = NULL)
}

# % improvement on each metric inside and outside the box, from one XGBoost model to another
zone_improvement <- function(from, to) {
  out("zone_metrics") |>
    filter(model == "xgboost", tier %in% c(from, to)) |>
    select(in_box, tier, AUROC = auc, `PR-AUC` = pr_auc, Brier = brier, `Log loss` = log_loss) |>
    pivot_longer(c(AUROC, `PR-AUC`, Brier, `Log loss`), names_to = "metric") |>
    pivot_wider(names_from = tier, values_from = value) |>
    rename(a = all_of(from), b = all_of(to)) |>
    mutate(improvement = if_else(metric %in% lower_better, 1 - b / a, b / a - 1) * 100,
           zone = if_else(in_box, "Inside the box", "Outside the box"),
           comparison = paste(tier_short[from], "XGB to", tier_short[to], "XGB"),
           metric = factor(metric, levels = rev(c("AUROC", "PR-AUC", "Brier", "Log loss"))))
}
