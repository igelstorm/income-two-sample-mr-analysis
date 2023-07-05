suppressPackageStartupMessages({
  library(cause)
  library(dplyr)
})

source("scripts/results/tidiers.R")

mr_paths <- dir(here::here("output/analysis/mr"), full.names = TRUE)
output_file <- here::here("output/results/mr_estimates.csv")

methods <- tribble(
  ~"method", ~"input_file",
  "mr_egger", "mr_input",
  "mr_ivw", "mr_input",
  "mr_mbe_unweighted", "mr_input",
  "mr_mbe_weighted", "mr_input",
  "mr_median", "mr_input",
  "steiger_mr_egger", "steiger_mr_input",
  "steiger_mr_ivw", "steiger_mr_input",
  "steiger_mr_mbe_unweighted", "steiger_mr_input",
  "steiger_mr_mbe_weighted", "steiger_mr_input",
  "steiger_mr_median", "steiger_mr_input"
)

# Get F statistic from MRInput objects - this is not available from any of the model objects
snp_stats <- tibble(path = list.files(mr_paths, full.names = TRUE)) |>
  filter(grepl("mr_input", path)) |>
  mutate(model = lapply(path, readRDS)) |>
  mutate(glance = lapply(model, broom::glance)) |>
  tidyr::unnest(glance) |>
  tidyr::extract(
    path,
    c("exposure", "outcome", "input_file"),
    regex = "^.*mr\\/(.*)__(.*)\\/(.*)\\.rds"
  ) |>
  select(exposure, outcome, input_file, f.statistic.mean)

mr_models <- tibble(path = list.files(mr_paths, full.names = TRUE)) |>
  filter(!grepl("mr_input", path)) |>
  mutate(model = lapply(path, readRDS)) |>
  tidyr::extract(
    path,
    c("exposure", "outcome", "method"),
    regex = "^.*mr\\/(.*)__(.*)\\/(.*)\\.rds"
  ) |>
  left_join(methods, by = c("method")) |>
  left_join(snp_stats, by = c("exposure", "outcome", "input_file"))

results <- mr_models |>
  mutate(tidy = lapply(model, broom::tidy)) |>
  mutate(glance = lapply(model, broom::glance)) |>
  tidyr::unnest(tidy) |>
  tidyr::unnest(glance) |>
  select(
    exposure,
    outcome,
    method,
    term,
    nobs,
    i.squared,
    f.statistic.mean,
    estimate,
    std.error,
    conf.low,
    conf.high,
    p.value,
  )

results |>
  arrange(exposure, outcome, method) |>
  readr::write_csv(file = output_file, na = "")
