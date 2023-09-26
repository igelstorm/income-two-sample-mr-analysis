# Income two-sample MR

## Requirements

- [R](https://www.r-project.org/)
- [GNU Make](https://www.gnu.org/software/make/) (for running the complete analysis pipeline)
- [curl](https://www.curl.se/) (for downloading files)
- [tar](https://www.gnu.org/software/tar/) (for extracting `tar` archives)
- [PLINK 1.9](https://www.cog-genomics.org/plink/) (for clumping genetic summary data)
- Depending on your platform, you may need of the following to install some of the required R packages:
  - **(Windows)** [Rtools](https://cran.r-project.org/bin/windows/Rtools/)
  - **(Mac)** [Xcode]() or [Xcode Command Line Tools](https://mac.install.guide/commandlinetools/index.html)
  - **(Linux)** a C/C++ compiler (in Debian/Ubuntu, the packages `build-essential` or `r-base-dev` should contain everything necessary)

The most convenient way to install these tools might be by using a package manager appropriate for your system, e.g. apt on Debian/Ubuntu, [Scoop](https://scoop.sh/) on Windows, or [Homebrew](https://brew.sh/) on OS X.

If your PLINK executable is in a non-standard location, or is named something other than `plink1.9.exe`, you may need to edit the `plink_executable` variable at the top of the Makefile accordingly.

## Setting up the R environment

- Install [renv](https://rstudio.github.io/renv/index.html):
  - In R: `install.packages("renv")`
  - From the command line: `Rscript -e 'install.packages("renv")'`
- Install other required R packages:
  - In R: `renv::restore()`
  - From the command line: `make packages`

## Downloading data

- Most data sets are publicly available, and are automatically downloaded as part of the analyses.
- Within-family (sibship-adjusted) income GWAS data were obtained directly from the [Within Family Consortium](https://www.withinfamilyconsortium.com/home/). These data should eventually be publicly available, but in the meantime, users who want to replicate the within-family analyses would need to request them from the authors and create the following files:
  - `input/data/siblinggwas/Income_WS_mtag_meta.txt`
  - `input/data/siblinggwas/income-study-summary.txt`

## Running the analyses

- The analyses can be run from the command line using `make`; this runs the required R scripts in the right order as defined in `Makefile`.
- Run all analyses: `make all`
- Run MR analyses only: `make mr`
- Run CAUSE analyses only (time-consuming): `make cause`
- Run multivariable MR analyses only (time-consuming): `make mvmr`

## Understanding the results

After running the analyses, the results are reported in CSV format in the `output/results/` directory:

- `cause_results.csv` contains results from the CAUSE analysis
- `mr_estimates.csv` contains results from the IVW, median, mode-based, and MR-Egger analyses
- `mvmr_estimates.csv` contains results from the multivariable MR analyses
- `mvmr_stats.csv` contains information about the instruments used for the exposures in the multivariable MR analyses (number of SNPs and conditional F-statistics)

Exposures and outcomes in these files are denoted using the identifiers specified in `input/metadata.csv`.

### Folder structure

- `input/`: contains GWAS data (needed for the analyses) and linkage disequilibrium reference panel data (needed for clumping GWAS data)
- `output/`: contains results of the analyses:
  - `output/analysis/`: raw output from each analysis (not human-readable)
  - `output/data/`: pre-processed and clumped datasets
  - `output/results/`: formatted analysis results (see above)
- `renv/`: contains installed R packages
- `scripts/`: contains all R code for data processing and analysis
  - The subdirectories correspond to the subdirectories in `output/`.
  - There is no "master" script which runs the entire analysis. Instead, the order in which these scripts are run is defined in `Makefile`, and the analyses are run using the `make` command.

After running the analyses, the `input` and `output` folders will contain a number of very large files. Some of these can be deleted if necessary to conserve disk space. In particular:

- `input/data/`
- `input/ld_ref_panel/`
- `output/data/`
