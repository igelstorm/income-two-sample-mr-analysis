library(data.table)

# Birthweight

# http://egg-consortium.org/

url <- "http://egg-consortium.org/BW3/BW3_EUR_summary_stats.txt.gz"
output_path <- "output/data/birthweight.feather"
input_path <- "input/data/BW3_EUR_summary_stats.txt.gz"
if (!file.exists(input_path)) { download.file(url, input_path, mode = "wb") }

data <- fread(input_path, select = c("rsid", "effect_allele", "other_allele", "eaf", "beta", "se", "p", "n"))
setnames(data, c("effect_allele", "other_allele"), c("a1", "a2"))

data[, study_id := "birthweight"]
data[, phenotype := "Birth weight"]
data[, model := "continuous"]
setkey(data, rsid)
arrow::write_feather(data, output_path)
