library(TwoSampleMR)
library(dplyr)
library(data.table)
library(ieugwasr)
library(optparse)

opt_parser <- OptionParser(option_list = list(
  make_option("--exposure", type = "character", help = "Exposure dataset ID"),
  make_option("--outcome", type = "character", help = "Outcome dataset ID")
))
opt <- parse_args(opt_parser)

clumped_data <- here::here(sprintf("output/analysis/clumped_data/%s__%s", opt$exposure, opt$outcome))
output_folder <- here::here(sprintf("output/analysis/mr/%s__%s", opt$exposure, opt$outcome))
dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

exposure_file <- here::here(sprintf("output/data/%s.feather", opt$exposure))
outcome_file <- here::here(sprintf("output/data/%s.feather", opt$outcome))

if (opt$exposure == "sibling_income") {
  # Use main income GWAS to identify SNPs for sibling-adjusted exposure
  identification_file <- here::here("output/data/income_kweon.feather")
} else {
  identification_file <- here::here(sprintf("output/data/%s.feather", opt$exposure))
}

# exposure_file <- "output/data/income_kweon.feather"
# outcome_file <- "output/data/ieu-a-835.feather"
# identification_file <- "output/data/income_kweon.feather"

output_file <- here::here(sprintf("output/analysis/clumped_data/%s__%s.rds", opt$exposure, opt$outcome))

print(paste("Exposure dataset:      ", exposure_file))
print(paste("Outcome dataset:       ", outcome_file))
print(paste("Identification dataset:", identification_file))
print(paste("Output file:           ", output_file))

exposure_data <- arrow::read_feather(exposure_file)
outcome_data <- arrow::read_feather(outcome_file)
identification_data <- arrow::read_feather(identification_file)

# Identify significant SNPs in the identification dataset that are also present
# in the exposure and outcome datasets
shared_significant_rsids <- Reduce(intersect, list(
  identification_data[p < 5e-8, rsid],
  exposure_data$rsid,
  outcome_data$rsid
))

# Clump SNPs using p values from the identification dataset
clumped <- ld_clump(
  identification_data[shared_significant_rsids, .(rsid, pval = p)],
  clump_kb = 10000,
  clump_r2 = 0.001,
  clump_p = 0.99,
  bfile = "input/ld_ref_panel/EUR",
  plink_bin = here::here("bin/plink.exe")
)

clumped_exposure <- exposure_data[clumped$rsid]
clumped_outcome <- outcome_data[clumped$rsid]

# Estimate R^2 for continuous phenotypes
if (clumped_exposure$model[[1]] == "continuous") {
  clumped_exposure[, r := get_r_from_bsen(b = beta, se = se, n = n)]
} else {
  clumped_exposure[, r := NA]
}
if (clumped_outcome$model[[1]] == "continuous") {
  clumped_outcome[, r := get_r_from_bsen(b = beta, se = se, n = n)]
} else {
  clumped_outcome[, r := NA]
}

setnames(
  clumped_exposure,
  c("rsid", "study_id", "phenotype", "beta", "se",
    "p", "eaf", "a1", "a2", "r"),
  c("SNP", "id.exposure", "exposure", "beta.exposure", "se.exposure",
    "pval.exposure", "eaf.exposure", "effect_allele.exposure", "other_allele.exposure", "rsq.exposure"),
  skip_absent = TRUE
)
setnames(
  clumped_outcome,
  c("rsid", "study_id", "phenotype", "beta", "se",
    "p", "eaf", "a1", "a2", "r"),
  c("SNP", "id.outcome", "outcome", "beta.outcome", "se.outcome",
    "pval.outcome", "eaf.outcome", "effect_allele.outcome", "other_allele.outcome", "rsq.outcome"),
  skip_absent = TRUE
)

harmonised_data <- harmonise_data(
  exposure_dat = clumped_exposure,
  outcome_dat = clumped_outcome
) %>%
  mutate(steiger_dir = rsq.exposure > rsq.outcome)

saveRDS(harmonised_data, output_file)
