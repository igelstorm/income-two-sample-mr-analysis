tictoc::tic("Startup")

suppressPackageStartupMessages({
  library(dplyr)
  library(data.table)
  library(optparse)
})

opt_parser <- OptionParser(option_list = list(
  make_option("--exposure", type = "character", help = "Exposure dataset ID"),
  make_option("--outcome", type = "character", help = "Outcome dataset ID")
))
opt <- parse_args(opt_parser)

clumped_data <- here::here(sprintf("output/analysis/clumped_data/%s__%s.rds", opt$exposure, opt$outcome))
output_folder <- here::here(sprintf("output/analysis/mr/%s__%s", opt$exposure, opt$outcome))
dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

# Number of bootstrap iterations
# Suggested: 100 for fast feedback during development,
# 10000 when running for real
iterations <- 10000

harmonised_data <- readRDS(clumped_data)

tictoc::tic("mr_input")
input <- MendelianRandomization::mr_input(
  bx = harmonised_data$beta.exposure,
  bxse = harmonised_data$se.exposure,
  by = harmonised_data$beta.outcome,
  byse = harmonised_data$se.outcome,
  snps = harmonised_data$SNP
)
saveRDS(input, file.path(output_folder, "mr_input.rds"))
tictoc::toc()

tictoc::tic("mr_ivw")
saveRDS(MendelianRandomization::mr_ivw(input),
  file.path(output_folder, "mr_ivw.rds"))
tictoc::toc()

if (length(input$snps) > 2) {
  tictoc::tic("mr_egger")
  saveRDS(MendelianRandomization::mr_egger(input),
    file.path(output_folder, "mr_egger.rds"))
  tictoc::toc()

  tictoc::tic("mr_median")
  saveRDS(MendelianRandomization::mr_median(input, iterations = iterations),
    file.path(output_folder, "mr_median.rds"))
  tictoc::toc()

  tictoc::tic("mr_mbe_unweighted")
  saveRDS(MendelianRandomization::mr_mbe(input, weighting = "unweighted", iterations = iterations),
    file.path(output_folder, "mr_mbe_unweighted.rds"))
  tictoc::toc()

  tictoc::tic("mr_mbe_weighted")
  saveRDS(MendelianRandomization::mr_mbe(input, weighting = "weighted", iterations = iterations),
    file.path(output_folder, "mr_mbe_weighted.rds"))
  tictoc::toc()
}

# Only run Steiger-filtered analyses if any SNPs remain after filtering
if (any(harmonised_data$steiger_dir, na.rm = TRUE)) {
  filtered_data <- filter(harmonised_data, steiger_dir)
  steiger_input <- MendelianRandomization::mr_input(
    bx = filtered_data$beta.exposure,
    bxse = filtered_data$se.exposure,
    by = filtered_data$beta.outcome,
    byse = filtered_data$se.outcome,
    snps = filtered_data$SNP
  )
  saveRDS(steiger_input, file.path(output_folder, "steiger_mr_input.rds"))

  tictoc::tic("steiger_mr_ivw")
  saveRDS(MendelianRandomization::mr_ivw(steiger_input),
    file.path(output_folder, "steiger_mr_ivw.rds"))
  tictoc::toc()

  if (length(steiger_input$snps) > 2) {
    tictoc::tic("steiger_mr_egger")
    saveRDS(MendelianRandomization::mr_egger(steiger_input),
      file.path(output_folder, "steiger_mr_egger.rds"))
    tictoc::toc()

    tictoc::tic("steiger_mr_median")
    saveRDS(MendelianRandomization::mr_median(steiger_input, iterations = iterations),
      file.path(output_folder, "steiger_mr_median.rds"))
    tictoc::toc()

    tictoc::tic("steiger_mr_mbe_unweighted")
    saveRDS(MendelianRandomization::mr_mbe(steiger_input, weighting = "unweighted", iterations = iterations),
      file.path(output_folder, "steiger_mr_mbe_unweighted.rds"))
    tictoc::toc()

    tictoc::tic("steiger_mr_mbe_weighted")
    saveRDS(MendelianRandomization::mr_mbe(steiger_input, weighting = "weighted", iterations = iterations),
      file.path(output_folder, "steiger_mr_mbe_weighted.rds"))
    tictoc::toc()
  }
}
