# Income two-sample MR

## Requirements

- [R](https://www.r-project.org/)
- [GNU Make](https://www.gnu.org/software/make/) (for running the complete analysis pipeline)
- [curl](https://www.curl.se/) (for downloading files)
- [tar](https://www.gnu.org/software/tar/) (for extracting `tar` archives)
- [PLINK 1.9](https://www.cog-genomics.org/plink/) (for clumping genetic summary data)

The most convenient way to install these tools might be by using a package manager appropriate for your system, e.g. apt on Debian/Ubuntu, [Scoop](https://scoop.sh/) on Windows, or [Homebrew](https://brew.sh/) on OS X.

If your PLINK executable is in a non-standard location, or is named something other than `plink1.9`, you may need to edit the `plink_executable` variable at the top of the Makefile accordingly.

## Setting up the R environment

- Install [renv](https://rstudio.github.io/renv/index.html):
  - In R: `install.packages("renv")`
  - From the command line: `Rscript -e 'install.packages("renv")'`
- Install other required R packages:
  - In R: `renv::restore()`
  - From the command line: `make packages`

## Downloading data

- Most data sets are publicly available, and are automatically downloaded as part of the analyses.
- There is one exception: The sibling-adjusted income GWAS data are not yet publicly available. In order to run these analyses, the following files need to be present in the `input/data/siblinggwas/` directory:
  - `Income_WS_mtag_meta.txt`
  - `income-study-summary.txt`

## Running the analyses

- The analyses can be run from the command line using `make`; this runs the required R scripts in the right order as defined in `Makefile`.
- Run all analyses: `make all`
- Run MR analyses only: `make mr`
- Run CAUSE analyses only (time-consuming): `make cause`
- Run multivariable MR analyses only (time-consuming): `make mvmr`
