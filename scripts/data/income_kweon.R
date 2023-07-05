library(data.table)

# https://osf.io/rg8sh/

url <- "https://osf.io/download/z69v8/"
output_path <- "output/data/income_kweon.feather"
input_path <- "input/data/income_kweon.txt.gz"
if (!file.exists(input_path)) { download.file(url, input_path) }

data <- fread(
  input_path,
  select = c("SNP", "CHR", "BP", "A1", "A2", "EAF", "BETA", "SE", "P"),
  col.names = c("rsid", "chr", "bp", "a1", "a2", "eaf", "beta", "se", "p")
)
data[, study_id := "kweon_income"]
data[, phenotype := "Income"]
data[, n := 282963]
data[, model := "continuous"]

setkey(data, rsid)
arrow::write_feather(data, output_path)
