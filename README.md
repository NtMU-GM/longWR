# longWR

longWR is an R package in development for estimating the marginal win ratio
comparing always-treated (11) and never-treated (00) regimes with two binary
treatment decisions. Phase 0 provides an installable scaffold. See
[SPEC.md](SPEC.md) for the scientific design and
[DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) for milestone gates.

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

The development version is `0.1.0.9000`. Release metadata awaits approved
author attribution, a maintainer email, and a license decision.
