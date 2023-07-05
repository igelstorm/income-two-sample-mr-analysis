library(data.table)
library(MendelianRandomization)
library(optparse)

opt_parser <- OptionParser(option_list = list(
  make_option("--outcome", type = "character", help = "Outcome dataset ID")
))
opt <- parse_args(opt_parser)

exposure_file <- here::here("output/data/mvmr_exposure_data_all.feather")
outcome_file <- here::here(sprintf("output/data/%s.feather", opt$outcome))

output_folder <- here::here(sprintf("output/analysis/mvmr/%s", opt$outcome))
dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

# exposure_file <- "output/data/mvmr_exposure_data_all.feather"
# outcome_file <- "output/data/birthweight.feather"

print("Reading data")
exposure_data <- arrow::read_feather(exposure_file)
outcome_data <- arrow::read_feather(outcome_file)

print("Merging exposure and outcome datasets")
joined <- merge(exposure_data, outcome_data)

# swap alleles to align with exposure data
joined[a1.x != a1.y, c("beta", "a1.y", "a2.y") := .(-beta, a2.y, a1.y)]
# remove rows where there is still a mismatch
joined <- joined[a1.x == a1.y & a2.x == a2.y]

# Use p-value from income to determine index SNP when clumping
joined[, pval := p.inc]

print("Clumping")
clumped <- ieugwasr::ld_clump(
  joined,
  clump_kb = 10000,
  clump_r2 = 0.001,
  bfile = here::here("input/ld_ref_panel/EUR"),
  plink_bin = here::here("bin/plink.exe")
)

# Save list of SNPs before and after clumping
fwrite(
  joined[, .(rsid, beta.inc, beta.edu, se.inc, se.edu, p.inc, p.edu)],
  file.path(output_folder, "snps_before_clumping.csv")
)
fwrite(
  clumped[, .(rsid, beta.inc, beta.edu, se.inc, se.edu, p.inc, p.edu)],
  file.path(output_folder, "snps_after_clumping.csv")
)

print("Running analyses (MVMR package)")
formatted <- MVMR::format_mvmr(
  BXGs = clumped[, .(beta.inc, beta.edu)],
  BYG = clumped$beta,
  seBXGs = clumped[, .(se.inc, se.edu)],
  seBYG = clumped$se,
  RSID = clumped$rsid
)

overlap <- clumped[, .(inc_sig = p.inc < 5e-8, edu_sig = p.edu < 5e-8)][, .(
  inc_only = sum(inc_sig & !edu_sig),
  edu_only = sum(edu_sig & !inc_sig),
  both = sum(inc_sig & edu_sig)
)]
fwrite(overlap, file.path(output_folder, "overlap_snp_counts.csv"))

fwrite(
  MVMR::strhet_mvmr(formatted),
  file.path(output_folder, "strhet_mvmr.csv")
)
fwrite(
  MVMR::strength_mvmr(formatted),
  file.path(output_folder, "strength_mvmr.csv")
)
fwrite(
  MVMR::ivw_mvmr(formatted),
  file.path(output_folder, "ivw_mvmr.csv")
)

mvinput <-   mr_mvinput(
  bx = as.matrix(clumped[, .(beta.inc, beta.edu)]),
  bxse = as.matrix(clumped[, .(se.inc, se.edu)]),
  by = clumped$beta,
  byse = clumped$se,
  exposure = c("income", "education"),
  outcome = opt$outcome,
  snps = clumped$rsid
)

m <- mr_mvivw(mvinput)
sink(file = file.path(output_folder, "mr_mvivw.txt"))
m
sink(file = NULL)
saveRDS(m, file.path(output_folder, "mr_mvivw.rds"))

m <- mr_mvivw(mvinput, robust = TRUE)
sink(file = file.path(output_folder, "mr_mvivw_robust.txt"))
m
sink(file = NULL)
saveRDS(m, file.path(output_folder, "mr_mvivw_robust.rds"))

m <- mr_mvegger(mvinput, orientate = 1)
sink(file = file.path(output_folder, "mr_mvegger.txt"))
m
sink(file = NULL)
saveRDS(m, file.path(output_folder, "mr_mvegger.rds"))

m <- mr_mvmedian(mvinput)
sink(file = file.path(output_folder, "mr_mvmedian.txt"))
m
sink(file = NULL)
saveRDS(m, file.path(output_folder, "mr_mvmedian.rds"))

m <- mr_mvlasso(mvinput, orientate = 1)
sink(file = file.path(output_folder, "mr_mvlasso.txt"))
m
sink(file = NULL)
saveRDS(m, file.path(output_folder, "mr_mvlasso.rds"))
