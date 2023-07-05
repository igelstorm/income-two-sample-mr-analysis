library(data.table)
library(optparse)

opt_parser <- OptionParser(option_list = list(
  make_option("--variable", type = "character", help = "Variable ID")
))
opt <- parse_args(opt_parser)

# OpenGWAS

info <- list(
  "ieu-a-835"  = list(phenotype = "Body mass index", model  = "continuous"),
  "ieu-a-1239" = list(phenotype = "Education", model  = "continuous"),
  "ieu-a-1009" = list(phenotype = "Subjective well-being", model = "continuous"),
  "ieu-b-4815" = list(phenotype = "Sibling BMI", model = "continuous"),
  "ieu-b-4833" = list(phenotype = "Sibling Alcohol", model = "continuous"),
  "ieu-b-4835" = list(phenotype = "Sibling Education", model = "continuous"),
  "ieu-b-4839" = list(phenotype = "Sibling Depressive", model = "continuous"),
  "ieu-b-4851" = list(phenotype = "Sibling Wellbeing", model = "continuous"),
  "ieu-b-4857" = list(phenotype = "Sibling EverSmk", model = "logit",
                      n = 44052, prevalence = 0.5)
)

study_id <- opt$variable
study_info <- info[[study_id]]

url <- sprintf("https://gwas.mrcieu.ac.uk/files/%s/%s.vcf.gz", study_id, study_id)
download_path <- sprintf("input/data/%s.vcf.gz", study_id)
data_path <- sprintf("output/data/%s.feather", study_id)

if (!file.exists(download_path)) { download.file(url, download_path) }

tictoc::tic()
print(paste0(study_id, ": Reading VCF"))

data <- fread(download_path, skip = "#CHROM")
data[, rownum := .I]

print(paste0(study_id, ": Parsing VCF custom data"))
custom_data <- data.table(
  rownum = data$rownum,
  data = strsplit(data[[10]], ":", fixed = TRUE),
  format = strsplit(data$FORMAT, ":", fixed = TRUE)
)

custom_data <- tidyfast::dt_hoist(custom_data, data, format)
custom_data <- dcast(custom_data, rownum ~ format, value.var = "data")

if (is.null(custom_data$AF)) { custom_data[, AF := NA] }
custom_data[, AF := as.numeric(AF)]
custom_data[, ES := as.numeric(ES)]
custom_data[, LP := as.numeric(LP)]
custom_data[, SE := as.numeric(SE)]
custom_data[, SS := as.numeric(SS)]

print(paste0(study_id, ": Writing output"))

data <- data[
  custom_data,
  .(
    rsid = ID,
    chr = `#CHROM`,
    bp = POS,
    a1 = ALT,
    a2 = REF,
    eaf = AF,
    beta = ES,
    se = SE,
    n = SS,
    p = 10^(-LP),
    model = study_info$model,
    study_id = study_id,
    phenotype = study_info$phenotype
  ),
  on = "ID"
]
if (study_info$model == "logit") {
  data[, ncase      := study_info$n * study_info$prevalence]
  data[, ncontrol   := study_info$n * (1 - study_info$prevalence)]
  data[, prevalence := study_info$prevalence]
}
setkey(data, rsid)
arrow::write_feather(data, data_path)

rm(data)
rm(custom_data)
tictoc::toc()
