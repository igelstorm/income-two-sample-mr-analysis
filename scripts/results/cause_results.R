library(cause)
library(dplyr)

source("scripts/results/tidiers.R")

mr_outcomes <- c(
  "F5_DEPRESSIO",
  "F5_ALLANXIOUS",
  "ieu-a-1009", # Subjective wellbeing
  "DEATH",
  "ieu-a-835",  # Body mass index
  "ASTHMA_CHILD_EXMORE",
  "birthweight",
  "SmokingInitiation",
  "CigarettesPerDay",
  "DrinksPerWeek"
)
cause_paths <- dir(
  here::here("output/analysis/cause"),
  pattern = "model.rds",
  recursive = TRUE,
  full.names = TRUE
)
output_file <- here::here("output/results/cause_results.csv")

tibble(path = cause_paths) %>%
  mutate(
    model = lapply(path, readRDS),
    tidy = lapply(model, broom::tidy),
    glance = lapply(model, broom::glance),
  ) %>%
  tidyr::unnest(tidy) %>%
  tidyr::unnest(glance) %>%
  tidyr::extract(
    path,
    c("exposure", "outcome"),
    regex = "^.*cause\\/(.*)__(.*)\\/model\\.rds"
  ) %>%
  select(-model) %>%
  arrange(exposure, outcome) %>%
  readr::write_csv(output_file)
