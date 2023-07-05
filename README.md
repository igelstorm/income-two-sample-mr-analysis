# Income two-sample MR

## Requirements

- [R](https://www.r-project.org/)
- [GNU Make](https://www.gnu.org/software/make/)

## Setting up the R environment

- Install [renv](https://rstudio.github.io/renv/index.html):
  - In R: `install.packages("renv")`
  - From the command line: `Rscript -e 'install.packages("renv")'`
- Install other required R packages:
  - In R: `renv::restore()`
  - From the command line: `make packages`

## Downloading data

- Most data sets are publicly available, and are automatically downloaded as part of the analyses.
- There are a few exceptions:
  - The education GWAS data must be downloaded manually from the [SSGAC Data Portal](https://thessgac.com/) (requires login). Download `GWAS_EA_excl23andMe.txt` and place it in the `input/data/` directory.
  - The sibling-adjusted income GWAS data are not yet publicly available. In order to run these analyses, the following files need to be present in the `input/data/siblinggwas/` directory:
    - `Income_WS_mtag_meta.txt`
    - `income-study-summary.txt`

## Running the analyses

- The analyses can be run from the command line using `make`; this runs the required R scripts in the right order as defined in `Makefile`.
- Run all analyses: `make all`
- Run MR analyses only: `make mr`
- Run CAUSE analyses only (time-consuming): `make cause`
- Run multivariable MR analyses only (time-consuming): `make mvmr`
