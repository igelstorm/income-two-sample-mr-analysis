OUTCOMES = [
    "F5_DEPRESSIO", "F5_ALLANXIOUS", "ieu-a-1009", "DEATH", "ieu-a-835",
    "ASTHMA_CHILD_EXMORE", "birthweight", "SmokingInitiation",
    "CigarettesPerDay", "DrinksPerWeek",
]
SIBLING_OUTCOMES = ["ieu-b-4815", "ieu-b-4833", "ieu-b-4835", "ieu-b-4839", "ieu-b-4851", "ieu-b-4857"]

rule results:
    input:
        "output/results/mr_estimates.csv",
        "output/results/cause_results.csv",
        "output/results/mvmr_estimates.csv",

rule packages:
    shell: 'Rscript -e "renv::restore()"'

rule mr_results:
    output: "output/results/mr_estimates.csv"
    input:
        expand("output/analysis/mr/income_kweon__{outcome}", outcome=OUTCOMES),
        expand("output/analysis/mr/{exposure}__income_kweon", exposure=OUTCOMES),
        expand("output/analysis/mr/sibling_income__{outcome}", outcome=SIBLING_OUTCOMES),
    script: "scripts/results/mr_estimates.R"

rule cause_results:
    output: "output/results/cause_results.csv"
    input: expand("output/analysis/cause/income_kweon__{outcome}", outcome=OUTCOMES)
    script: "scripts/results/cause_results.R"

rule mvmr_results:
    output: "output/results/mvmr_estimates.csv"
    # input: $(mvmr_output)
    script: "scripts/results/mvmr_estimates.R"

rule mvmr_stats:
    output: "output/results/mvmr_stats.csv"
    input: "output/data/mvmr_exposure_data_clumped.feather"
    script: "scripts/results/mvmr_stats.R"

################################################################################
# Run analyses
################################################################################
rule mr_analysis:
    output: directory("output/analysis/mr/{exposure}__{outcome}")
    input: "output/analysis/clumped_data/{exposure}__{outcome}.rds"
    shell: "Rscript scripts/analysis/primary_mr_and_steiger.R --exposure {wildcards.exposure} --outcome {wildcards.outcome}"

rule cause_analysis:
    output: directory("output/analysis/cause/{exposure}__{outcome}")
    input: "output/data/{exposure}.feather", "output/data/{outcome}.feather"
    # $(clumping_dependencies)
    shell: "Rscript scripts/analysis/cause.R --exposure {wildcards.exposure} --outcome {wildcards.outcome}"

rule mvmr_analysis:
    output: directory("output/analysis/mvmr/{outcome}")
    input: "output/data/mvmr_exposure_data_all.feather", "output/data/{outcome}.feather"
    shell: "Rscript scripts/analysis/mvmr.R --outcome {wildcards.outcome}"

################################################################################
# Prepare clumped datasets
################################################################################
CLUMPING_DEPENDENCIES = [
    "input/ld_ref_panel/EUR.bed",
    "input/ld_ref_panel/EUR.fam",
    "input/ld_ref_panel/EUR.bim",
    "bin/plink.exe",
]

rule mr_clumping:
    output: "output/analysis/clumped_data/{exposure}__{outcome}.rds"
    input: "output/data/{exposure}.feather", "output/data/{outcome}.feather", "output/data/income_kweon.feather", CLUMPING_DEPENDENCIES
    shell: "Rscript scripts/analysis/clumping.R --exposure {wildcards.exposure} --outcome {wildcards.outcome}"

rule mvmr_exposure_data:
    output: "output/data/mvmr_exposure_data_all.feather"
    input: "output/data/income_kweon.feather", "output/data/ieu-a-1239.feather", CLUMPING_DEPENDENCIES
    script: "scripts/analysis/prepare_mvmr_exposures.R"

################################################################################
# Download and clean GWAS data
################################################################################

rule clean_finngen:
    output: "output/data/{variable}.feather"
    input: "input/data/finngen/finngen_R8_{variable}.gz"
    wildcard_constraints: variable="ASTHMA_CHILD_EXMORE|DEATH|F5_.*"
    script: "scripts/data/_finngen.R --variable {variable}"

rule clean_opengwas:
    output: "output/data/ieu-{id}.feather"
    input: "input/data/ieu-{id}.vcf.gz"
    script: "scripts/data/_opengwas.R --variable ieu-{id}"

rule clean_liu:
    output:
        "output/data/CigarettesPerDay.feather",
        "output/data/DrinksPerWeek.feather",
        "output/data/SmokingInitiation.feather"
    input:
        "input/data/CigarettesPerDay.WithoutUKB.txt.gz",
        "input/data/DrinksPerWeek.WithoutUKB.txt.gz",
        "input/data/SmokingInitiation.WithoutUKB.txt.gz"

rule clean_other_gwas:
    output: "output/data/{variable}.feather"
    script: "scripts/data/{variable}.R"

################################################################################
# Download tool and data needed for offline clumping
################################################################################

rule download_ld_panel:
    input: HTTP.remote("http://fileserve.mrcieu.ac.uk/ld/1kg.v3.tgz", insecure=True, keep_local=True)
    output: 
        "input/ld_ref_panel/EUR.bed"
        "input/ld_ref_panel/EUR.fam"
        "input/ld_ref_panel/EUR.bim"
    shell: "tar -xzf {input} -C input/ld_ref_panel EUR.bed EUR.fam EUR.bim"

rule download_plink_binary:
    output: "bin/plink.exe"
    shell: "wget -O bin/plink.exe https://github.com/MRCIEU/genetics.binaRies/raw/master/binaries/Windows/plink.exe"
