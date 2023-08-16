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
	Rscript $< --exposure income_kweon --outcome $*

# MVMR analysis
output/analysis/mvmr/%/mr_mvivw.rds: scripts/analysis/mvmr.R output/data/mvmr_exposure_data_all.feather output/data/%.feather
	Rscript $< --outcome $*

################################################################################
# Prepare clumped datasets
################################################################################
clumping_dependencies = input/ld_ref_panel/EUR.bed input/ld_ref_panel/EUR.fam input/ld_ref_panel/EUR.bim bin/plink.exe

output/analysis/clumped_data/income_kweon__%.rds: scripts/analysis/clumping.R output/data/income_kweon.feather output/data/%.feather $(clumping_dependencies)
	Rscript $< --exposure income_kweon --outcome $*
output/analysis/clumped_data/%__income_kweon.rds: scripts/analysis/clumping.R output/data/income_kweon.feather output/data/%.feather $(clumping_dependencies)
	Rscript $< --exposure $* --outcome income_kweon
output/analysis/clumped_data/sibling_income__%.rds: scripts/analysis/clumping.R output/data/sibling_income.feather output/data/income_kweon.feather output/data/%.feather $(clumping_dependencies)
	Rscript $< --exposure sibling_income --outcome $*

output/data/mvmr_exposure_data_all.feather: scripts/analysis/prepare_mvmr_exposures.R output/data/income_kweon.feather output/data/ieu-a-1239.feather $(clumping_dependencies)
	Rscript $<

################################################################################
# Download and clean GWAS data
################################################################################

output/data/ASTHMA_CHILD_EXMORE.feather: scripts/data/_finngen.R
	Rscript $< --variable ASTHMA_CHILD_EXMORE
output/data/DEATH.feather: scripts/data/_finngen.R
	Rscript $< --variable DEATH
output/data/F5_ALLANXIOUS.feather: scripts/data/_finngen.R
	Rscript $< --variable F5_ALLANXIOUS
output/data/F5_DEPRESSIO.feather: scripts/data/_finngen.R
	Rscript $< --variable F5_DEPRESSIO

output/data/CigarettesPerDay.feather: scripts/data/_liu.R
	Rscript $< --variable CigarettesPerDay
output/data/DrinksPerWeek.feather: scripts/data/_liu.R
	Rscript $< --variable DrinksPerWeek
output/data/SmokingInitiation.feather: scripts/data/_liu.R
	Rscript $< --variable SmokingInitiation

output/data/ieu-%.feather: scripts/data/_opengwas.R
	Rscript $< --variable ieu-$*

output/data/sibling_income.feather: scripts/data/sibling_income.R output/data/ieu-b-4815.feather
	Rscript $<
output/data/%.feather: scripts/data/%.R
	Rscript $<

################################################################################
# Download tool and data needed for offline clumping
################################################################################

# Download and extract linkage disequilibrium reference panel
input/ld_ref_panel/EUR.bed input/ld_ref_panel/EUR.fam input/ld_ref_panel/EUR.bim: | input/ld_ref_panel.tgz
	tar -xzf $< -C input/ld_ref_panel EUR.bed EUR.fam EUR.bim
input/ld_ref_panel.tgz:
	wget -O $@ http://fileserve.mrcieu.ac.uk/ld/1kg.v3.tgz

# Download plink binary
bin/plink.exe:
	wget -O $@ https://github.com/MRCIEU/genetics.binaRies/raw/master/binaries/Windows/plink.exe
