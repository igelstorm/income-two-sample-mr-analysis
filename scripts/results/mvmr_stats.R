library(data.table)
library(MendelianRandomization)

input_file <- here::here("output/data/mvmr_exposure_data_clumped.feather")
output_file <- here::here("output/results/mvmr_stats.csv")

clumped <- arrow::read_feather(input_file)

formatted <- MVMR::format_mvmr(
  BXGs = clumped[, .(beta.inc, beta.edu)],
  BYG = 0,
  seBXGs = clumped[, .(se.inc, se.edu)],
  seBYG = 0,
  RSID = clumped$rsid
)

strength <- MVMR::strength_mvmr(formatted)

overlap <- clumped[, .(inc_sig = p.inc < 5e-8, edu_sig = p.edu < 5e-8)][, .(
  inc_only = sum(inc_sig & !edu_sig),
  edu_only = sum(edu_sig & !inc_sig),
  both = sum(inc_sig & edu_sig),
  inc_f_stat = strength$exposure1,
  edu_f_stat = strength$exposure2
)]

fwrite(overlap, output_file)
