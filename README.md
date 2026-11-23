# longWR

longWR is an R package in development for estimating the marginal win ratio
comparing always-treated (11) and never-treated (00) regimes with two binary
treatment decisions.

**Current status.** Phase 0 and Phase 1 are complete. The available estimator,
`longwr_estimate()`, compares outcomes in the observed 11 and 00 groups using
unit or caller-supplied subject weights. It prioritizes a lower binary adverse
event and uses a higher numeric score to break ties. Sequential weight fitting
and simulation are planned for Phase 2. The development plan covers the
remaining validation and release milestones. See [SPEC.md](SPEC.md) and
[DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md).

## Install and run the example

```r
# Install remotes first if needed with install.packages("remotes")
remotes::install_github("NtMU-GM/longWR")
library(longWR)
example(longwr_estimate)
```

The example uses custom column names and supplied weights. The expected win
ratio is 4.

## Local smoke test

Run from the repository root.

```sh
mkdir -p .r-library
R_LIBS_USER="$PWD/.r-library" R CMD INSTALL --install-tests .
R_LIBS_USER="$PWD/.r-library" Rscript --vanilla -e 'library(longWR); print(packageVersion("longWR"))'
```

To run the installed tests, install `testthat` in the project library if it
is missing, then run the smoke test.

```sh
R_LIBS_USER="$PWD/.r-library" Rscript --vanilla -e 'if (!requireNamespace("testthat", quietly = TRUE)) install.packages("testthat", repos = "https://cloud.r-project.org")'
R_LIBS_USER="$PWD/.r-library" Rscript --vanilla -e 'testthat::test_package("longWR", stop_on_failure = TRUE)'
```

Mingyuan Kang maintains longWR. The development version is `0.1.0.9000`.
The project uses the [GNU General Public License, version 3](LICENSE).
