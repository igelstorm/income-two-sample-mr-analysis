library(data.table)
library(cause)
library(optparse)

# https://jean997.github.io/cause/ldl_cad.html

opt_parser <- OptionParser(option_list = list(
  make_option("--exposure", type = "character", help = "Exposure dataset ID"),
  make_option("--outcome", type = "character", help = "Outcome dataset ID")
))
opt <- parse_args(opt_parser)

exposure_file <- here::here(sprintf("output/data/%s.feather", opt$exposure))
outcome_file <- here::here(sprintf("output/data/%s.feather", opt$outcome))

output_folder <- here::here(sprintf("output/analysis/cause/%s__%s", opt$exposure, opt$outcome))
dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

print(paste("Exposure dataset:      ", exposure_file))
print(paste("Outcome dataset:       ", outcome_file))

exposure_data <- arrow::read_feather(exposure_file)
outcome_data <- arrow::read_feather(outcome_file)

x <- gwas_merge(
  exposure_data,
  outcome_data,
  snp_name_cols = rep("rsid", 2),
  beta_hat_cols = rep("beta", 2),
  se_cols = rep("se", 2),
  A1_cols = rep("a1", 2),
  A2_cols = rep("a2", 2)
)

# Estimate nuisance parameters
samplesize <- 1000000
# samplesize <- 1000
set.seed(100)
varlist <- with(x, sample(snp, size = samplesize, replace = FALSE))
params <- est_cause_params(x, varlist)

saveRDS(params, file.path(output_folder, "params.rds"))

# Clump
to_clump <- exposure_data[x$snp, .(rsid, pval = p)]
clumped <- ieugwasr::ld_clump(
  to_clump,
  clump_r2 = 0.01,
  clump_p = 1e-3,
  bfile = "input/ld_ref_panel/EUR",
  plink_bin = here::here("bin/plink.exe")
)

top_vars <- clumped$rsid
x_clump <- x[x$snp %in% clumped$rsid, ]

# Fit CAUSE
res <- cause(x, param_ests = params, variants = top_vars)

# Save model object
saveRDS(res, file.path(output_folder, "model.rds"))

# Save model summary
sink(file.path(output_folder, "summary.txt"))
summary(res, ci_size = 0.95)
sink()

# Save elpd
readr::write_csv(res$elpd, file.path(output_folder, "elpd.csv"))
