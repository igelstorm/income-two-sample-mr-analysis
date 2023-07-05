suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

source("scripts/results/tidiers.R")

input_folders <- dir(here::here("output/analysis/mvmr"), full.names = TRUE)
output_file <- "output/results/mvmr_estimates.csv"

filenames <- c(
  "mr_mvivw.rds",
  "mr_mvivw_robust.rds",
  "mr_mvegger.rds",
  "mr_mvmedian.rds",
  "mr_mvlasso.rds"
)

fstats <- file.path(input_folders, "strength_mvmr.csv") |>
  lapply(readr::read_csv, show_col_types = FALSE, id = "path") |>
  bind_rows() |>
  extract(path, "outcome", regex = "\\/([^/]*)\\/strength_mvmr\\.csv$") |>
  rename(income = exposure1, education = exposure2) |>
  pivot_longer(-outcome, names_to = "term", values_to = "f_statistic")

results <- tibble(path = list.files(input_folders, full.names = TRUE, pattern = "\\.rds$")) |>
  filter(file.exists(path)) |>
  mutate(model = lapply(path, readRDS)) |>
  extract(
    path,
    c("outcome", "method"),
    regex = "^.*mvmr\\/(.*)\\/(.*)\\.rds"
  ) |>
  mutate(tidy = lapply(model, broom::tidy)) |>
  mutate(glance = lapply(model, broom::glance)) |>
  unnest(tidy) |>
  unnest(glance) |>
  select(
    outcome,
    method,
    term,
    nobs,
    estimate,
    std.error,
    conf.low,
    conf.high,
    p.value,
  )

results |>
  arrange(outcome, method, term) |>
  left_join(fstats, by = c("outcome", "term")) |>
  readr::write_csv(file = output_file, na = "")
