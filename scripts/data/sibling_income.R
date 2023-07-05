library(data.table)

# The input data files are currently not publicly available, and must be
# obtained by the user before running:
#   - input/data/siblinggwas/Income_WS_mtag_meta.txt
#   - input/data/siblinggwas/income-study-summary.txt

data <- fread(
  "input/data/siblinggwas/Income_WS_mtag_meta.txt",
  select = c("CHR", "BP", "A1", "A2", "mtag_beta", "mtag_se", "mtag_pval"),
  col.names = c("chr", "bp", "a1", "a2", "beta", "se", "p")
)
metadata <- fread("input/data/siblinggwas/income-study-summary.txt")

data[, study_id := "sibling_income"]
data[, phenotype := "Income WS"]
data[, n := sum(metadata$N)]
data[, eaf := NA]
data[, model := "continuous"]

# Get RSIDs from one of the sibling GWAS studies available from OpenGWAS
rsids <- arrow::read_feather("output/data/ieu-b-4815.feather", col_select = c(chr, bp, rsid))
data <- rsids[data, on = c("chr", "bp")]

setkey(data, rsid)
data_path <- "output/data/sibling_income.feather"
arrow::write_feather(data, data_path)

# Calculate average SD of phenotype
cat(
  metadata[, sum(SD * N) / sum(N)],
  file = "output/data/sibling_income.sd.txt"
)
