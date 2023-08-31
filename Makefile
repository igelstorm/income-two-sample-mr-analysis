plink_executable = "plink1.9.exe"

outcomes = F5_DEPRESSIO F5_ALLANXIOUS ieu-a-1009 DEATH ieu-a-835 ASTHMA_CHILD_EXMORE birthweight SmokingInitiation CigarettesPerDay DrinksPerWeek
sibling_outcomes = ieu-b-4815 ieu-b-4833 ieu-b-4835 ieu-b-4839 ieu-b-4851 ieu-b-4857

income_mr_output = $(patsubst %,output/analysis/mr/income_kweon__%/mr_ivw.rds,$(outcomes))
reverse_mr_output = $(patsubst %,output/analysis/mr/%__income_kweon/mr_ivw.rds,$(outcomes))
sibling_mr_output = $(patsubst %,output/analysis/mr/sibling_income__%/mr_ivw.rds,$(sibling_outcomes))
all_mr_output = $(income_mr_output) $(reverse_mr_output) $(sibling_mr_output)

cause_output = $(patsubst %,output/analysis/cause/income_kweon__%/model.rds,$(outcomes))
mvmr_output = $(patsubst %,output/analysis/mvmr/%/mr_mvivw.rds,$(outcomes))

.PHONY: results packages
.SECONDARY:

# Build all output files
all: mr cause mvmr
mr: output/results/mr_estimates.csv
cause: output/results/cause_results.csv
mvmr: output/results/mvmr_estimates.csv output/results/mvmr_stats.csv

# Install R dependencies (requires renv)
packages:
	Rscript -e "renv::restore()"

output/results/mr_estimates.csv: scripts/results/mr_estimates.R $(all_mr_output)
	Rscript $<
output/results/cause_results.csv: scripts/results/cause_results.R $(cause_output)
	Rscript $<
output/results/mvmr_estimates.csv: scripts/results/mvmr_estimates.R $(mvmr_output)
	Rscript $<
output/results/mvmr_stats.csv: scripts/results/mvmr_stats.R output/data/mvmr_exposure_data_all.feather
	Rscript $<

################################################################################
# Run analyses
################################################################################

# MR analysis
output/analysis/mr/income_kweon__%/mr_ivw.rds: scripts/analysis/primary_mr_and_steiger.R output/analysis/clumped_data/income_kweon__%.rds
	Rscript $< --exposure income_kweon --outcome $*
output/analysis/mr/%__income_kweon/mr_ivw.rds: scripts/analysis/primary_mr_and_steiger.R output/analysis/clumped_data/%__income_kweon.rds
	Rscript $< --exposure $* --outcome income_kweon
output/analysis/mr/sibling_income__%/mr_ivw.rds: scripts/analysis/primary_mr_and_steiger.R output/analysis/clumped_data/sibling_income__%.rds
	Rscript $< --exposure sibling_income --outcome $*

# CAUSE analysis
output/analysis/cause/income_kweon__%/model.rds: scripts/analysis/cause.R output/data/income_kweon.feather output/data/%.feather $(clumping_dependencies)
	Rscript $< --exposure income_kweon --outcome $* --plink-path $(plink_executable)

# MVMR analysis
output/analysis/mvmr/%/mr_mvivw.rds: scripts/analysis/mvmr.R output/data/mvmr_exposure_data_all.feather output/data/%.feather
	Rscript $< --outcome $* --plink-path $(plink_executable)

################################################################################
# Prepare clumped datasets
################################################################################
clumping_dependencies = input/ld_ref_panel/EUR.bed input/ld_ref_panel/EUR.fam input/ld_ref_panel/EUR.bim

output/analysis/clumped_data/income_kweon__%.rds: scripts/analysis/clumping.R output/data/income_kweon.feather output/data/%.feather $(clumping_dependencies)
	Rscript $< --exposure income_kweon --outcome $* --plink-path $(plink_executable)
output/analysis/clumped_data/%__income_kweon.rds: scripts/analysis/clumping.R output/data/income_kweon.feather output/data/%.feather $(clumping_dependencies)
	Rscript $< --exposure $* --outcome income_kweon --plink-path $(plink_executable)
output/analysis/clumped_data/sibling_income__%.rds: scripts/analysis/clumping.R output/data/sibling_income.feather output/data/income_kweon.feather output/data/%.feather $(clumping_dependencies)
	Rscript $< --exposure sibling_income --outcome $* --plink-path $(plink_executable)

output/data/mvmr_exposure_data_all.feather: scripts/analysis/prepare_mvmr_exposures.R output/data/income_kweon.feather output/data/ieu-a-1239.feather $(clumping_dependencies)
	Rscript $< --plink-path $(plink_executable)

################################################################################
# Clean/harmonise GWAS data
################################################################################

output/data/ASTHMA_CHILD_EXMORE.feather: scripts/data/_finngen.R input/data/finngen/finngen_R8_ASTHMA_CHILD_EXMORE.gz
	Rscript $< --variable ASTHMA_CHILD_EXMORE
output/data/DEATH.feather: scripts/data/_finngen.R input/data/finngen/finngen_R8_DEATH.gz
	Rscript $< --variable DEATH
output/data/F5_ALLANXIOUS.feather: scripts/data/_finngen.R input/data/finngen/finngen_R8_F5_ALLANXIOUS.gz
	Rscript $< --variable F5_ALLANXIOUS
output/data/F5_DEPRESSIO.feather: scripts/data/_finngen.R input/data/finngen/finngen_R8_F5_DEPRESSIO.gz
	Rscript $< --variable F5_DEPRESSIO

output/data/CigarettesPerDay.feather: scripts/data/_liu.R input/data/CigarettesPerDay.WithoutUKB.txt.gz
	Rscript $< --variable CigarettesPerDay
output/data/DrinksPerWeek.feather: scripts/data/_liu.R input/data/DrinksPerWeek.WithoutUKB.txt.gz
	Rscript $< --variable DrinksPerWeek
output/data/SmokingInitiation.feather: scripts/data/_liu.R input/data/SmokingInitiation.WithoutUKB.txt.gz
	Rscript $< --variable SmokingInitiation

output/data/ieu-%.feather: scripts/data/_opengwas.R input/data/ieu-%.vcf.gz
	Rscript $< --variable ieu-$*

output/data/sibling_income.feather: scripts/data/sibling_income.R output/data/ieu-b-4815.feather
	Rscript $<
output/data/income_kweon.feather: scripts/data/income_kweon.R input/data/income_kweon.txt.gz
	Rscript $<
output/data/birthweight.feather: scripts/data/birthweight.R input/data/BW3_EUR_summary_stats.txt.gz
	Rscript $<

################################################################################
# Download GWAS data
################################################################################

input/data/%.WithoutUKB.txt.gz:
	curl -o $@ https://conservancy.umn.edu/bitstream/handle/11299/201564/$*.WithoutUKB.txt.gz
input/data/finngen/finngen_R8_%.gz:
	curl -o $@ https://storage.googleapis.com/finngen-public-data-r8/summary_stats/finngen_R8_$*.gz
input/data/ieu-%.vcf.gz:
	curl -o $@ https://gwas.mrcieu.ac.uk/files/ieu-$*/ieu-$*.vcf.gz
input/data/BW3_EUR_summary_stats.txt.gz:
	curl -o $@ http://egg-consortium.org/BW3/BW3_EUR_summary_stats.txt.gz
input/data/income_kweon.txt.gz:
	curl -o $@ https://osf.io/download/z69v8/

################################################################################
# Download data needed for offline clumping
################################################################################

# Download and extract linkage disequilibrium reference panel
input/ld_ref_panel/EUR.bed input/ld_ref_panel/EUR.fam input/ld_ref_panel/EUR.bim &: input/ld_ref_panel.tgz
	tar -xzmf $^ -C input/ld_ref_panel EUR.bed EUR.fam EUR.bim
input/ld_ref_panel.tgz:
	curl -o $@ http://fileserve.mrcieu.ac.uk/ld/1kg.v3.tgz
