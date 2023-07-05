library(data.table)

# Educational attainment
#
# Data file available at: https://thessgac.com/
# Automated download is not possible, since users need to sign in and agree to
# terms. Please manually download "GWAS_EA_excl23andMe.txt" and place it in the
# "input/data" directory.

data <- fread(
  "input/data/GWAS_EA_excl23andMe.txt",
  select = c("MarkerName", "A1", "A2", "EAF", "Beta", "SE", "Pval"),
  col.names = c("rsid", "a1", "a2", "eaf", "beta", "se", "p")
)
data[, study_id := "lee_ea"]
data[, phenotype := "Educational attainment"]
data[, n := 566524]
data[, model := "continuous"]
setkey(data, rsid)
arrow::write_feather(data, "output/data/lee_ea.feather")
rm(data)
