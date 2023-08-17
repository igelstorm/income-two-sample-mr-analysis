library(data.table)
library(optparse)

opt_parser <- OptionParser(option_list = list(
  make_option("--variable", type = "character", help = "Variable ID")
))
opt <- parse_args(opt_parser)
study_id <- opt$variable

url <- sprintf("https://storage.googleapis.com/finngen-public-data-r8/summary_stats/%s.gz", study_id)
output_path <- here::here(sprintf("output/data/%s.feather", study_id))
input_path <- here::here(sprintf("input/data/finngen/finngen_R8_%s.gz", study_id))
if (!file.exists(input_path)) { download.file(url, input_path, mode = "wb") }

# For prevalences: https://r8.risteys.finngen.fi/
all_metadata <- list(
  ASTHMA_CHILD_EXMORE = list(model = "logit", ncase = 5505, prevalence = 0.0155),
  DEATH = list(model = "logit", ncase = 38936, prevalence = 0.1094),
  F5_ALLANXIOUS = list(model = "logit", ncase = 22442, prevalence = 0.0631),
  F5_DEPRESSIO = list(model = "logit", ncase = 39747, prevalence = 0.1117)
)

metadata <- all_metadata[[study_id]]

print(sprintf("Processing %s from %s", study_id, input_path))
data <- fread(
  input_path,
  select = c("rsids", "alt", "ref", "af_alt", "beta", "sebeta", "pval"),
  col.names = c("rsid", "a1", "a2", "eaf", "beta", "se", "p")
)

data[, study_id := study_id]
data[, phenotype := study_id]
data[, model := metadata$model]
if (metadata$model != "continuous") {
  data[, ncase := metadata$ncase]
  data[, ncontrol := metadata$ncase / metadata$prevalence - metadata$ncase]
  data[, prevalence := metadata$prevalence]
}
setkey(data, rsid)

arrow::write_feather(data, output_path)
rm(data)
