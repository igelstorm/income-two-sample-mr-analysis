library(data.table)
library(optparse)

# Liu alcohol and smoking
# https://conservancy.umn.edu/handle/11299/201564

opt_parser <- OptionParser(option_list = list(
  make_option("--variable", type = "character", help = "Variable ID")
))
opt <- parse_args(opt_parser)
study_id <- opt$variable

input_path <- sprintf("input/data/%s.WithoutUKB.txt.gz", study_id)
output_path <- sprintf("output/data/%s.feather", study_id)

all_metadata <- list(
  CigarettesPerDay  = list(model = "continuous"),
  DrinksPerWeek     = list(model = "continuous"),
  SmokingInitiation = list(model = "probit", prevalence = 0.5653)
)
metadata <- all_metadata[[study_id]]

print(sprintf("Processing %s", study_id))
data <- fread(
  input_path,
  select = c("RSID", "ALT", "REF", "AF", "BETA", "SE", "PVALUE", "N"),
  col.names = c("rsid", "a1", "a2", "eaf", "beta", "se", "p", "n")
)
data[, study_id := study_id]
data[, phenotype := study_id]
data[, model := metadata$model]
if (metadata$model != "continuous") {
  data[, ncase := n * metadata$prevalence]
  data[, ncontrol := n * (1 - metadata$prevalence)]
  data[, prevalence := metadata$prevalence]
}
setkey(data, rsid)
arrow::write_feather(data, output_path)
rm(data)
