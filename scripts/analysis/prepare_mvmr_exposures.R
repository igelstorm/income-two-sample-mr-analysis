library(data.table)
library(MendelianRandomization)

income_file <- "output/data/income_kweon.feather"
education_file <- "output/data/ieu-a-1239.feather"

print("Reading data")
inc_data <- arrow::read_feather(income_file)
edu_data <- arrow::read_feather(education_file)

print("Merging exposure datasets")
significant_snps <- c(
  inc_data[p < 5e-8, rsid],
  edu_data[p < 5e-8, rsid]
)

significant <- merge(
  inc_data[rsid %in% significant_snps],
  edu_data[rsid %in% significant_snps],
  suffixes = c(".inc", ".edu")
)

print("Aligning effect alleles")
# swap alleles to align with income data
significant[a1.inc != a1.edu, c("beta.edu", "a1.edu", "a2.edu") := .(-beta.edu, a2.edu, a1.edu)]
# remove rows where there is still a mismatch
significant <- significant[a1.inc == a1.edu & a2.inc == a2.edu]
setnames(significant, "a1.inc", "a1")
setnames(significant, "a2.inc", "a2")
significant[, c("a1.edu", "a2.edu", "chr.inc", "chr.edu", "bp.inc", "bp.edu") := NULL]


# Use p-value from inc (income) to determine index SNP when clumping
significant[, pval := p.inc]

print("Clumping")
clumped <- ieugwasr::ld_clump(
  significant,
  clump_kb = 10000,
  clump_r2 = 0.001,
  bfile = here::here("input/ld_ref_panel/EUR"),
  plink_bin = here::here("bin/plink.exe")
)

arrow::write_feather(significant, here::here("output/data/mvmr_exposure_data_all.feather"))
arrow::write_feather(clumped, here::here("output/data/mvmr_exposure_data_clumped.feather"))
