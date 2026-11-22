# Building longWR with a coding agent

## Phase 0 · Reproduce the scaffold

Start in the repository root. Read AGENTS.md, SPEC.md, and DEVELOPMENT_PLAN.md.
Use the local install and smoke-test commands in README.md. Inspect
`git show --stat 16e29be` to see the Phase 0 checkpoint. Verify exclusions with
`git check-ignore -v .r-library/testthat longWR.Rcheck/00check.log longWR_0.1.0.9000.tar.gz`.

## Phase 1 · Reproduce and review the direct estimator

1. Give the agent SPEC.md sections 2–4 and 8. Ask it to implement the schema
   and direct point estimator, test the hand calculation, and stop before
   fitting treatment models.
2. Inspect `R/schema.R` and `tests/testthat/test-schema.R` together. Trace a
   subject through a custom mapping. A switcher's endpoint must still pass
   validation because the data contract covers every input row.
3. Work the four pairs in the function example by hand. The two wins carry
   weights 8 and 4, the loss carries 3, and the tie carries 6. Divide each
   category total by 21 for its probability. The win ratio is 12/3.
4. Run the commands below from the repository root with the Phase 0 library.
   The example prints 4. With WINS available, the installed tests also check
   the corresponding weighted and crude WRs and both directional probabilities.
5. Review the result for a dataset containing only switchers. Its zero pair
   count, missing-history labels and reason explain the undefined estimate.
   Review a flipped 11/00 comparison to check the direction of the ratio.

```sh
export R_LIBS_USER="$PWD/.r-library"
Rscript --vanilla -e 'roxygen2::roxygenise()'
Rscript --vanilla -e 'testthat::test_local(".", reporter = "summary")'
R CMD INSTALL --install-tests .
Rscript --vanilla -e 'library(longWR); example(longwr_estimate); testthat::test_package("longWR", stop_on_failure = TRUE)'
```

For the implementation and independent arithmetic checks, see
[R/longwr_estimate.R](R/longwr_estimate.R) and
[tests/testthat/test-estimate.R](tests/testthat/test-estimate.R).

### Reproduce the Phase 1 review

Start by asking the agent to verify the existing estimator against SPEC.md
sections 2.4 and 8. Keep expected results independent of the estimator helpers.

- For the four-subject example, tabulate the raw weighted pairs by hand. For
  a second check, use small integer weights as repetition counts. Enumerating
  pairs of repeated observations gives the same weighted probabilities. The
  tests exercise all 81 assignments of three ordered outcomes to four subjects.
- For the WINS check, select 11 and 00, subset the weight vector in the same
  order, and put 11 first in `arm.name`. Use binary then continuous endpoints,
  directions `smaller` then `larger`, and zero margins. Compare only the
  point estimates, with 12 requested digits and a tolerance of 1e-10. Repeat
  with unit weights, then interleave the arms and use unequal regime sizes.
- For boundary cases, inspect both `status` and `reason`. A missing regime
  is visible in `missing_histories` even when a malformed weight value takes
  precedence. A positive probability can round to zero. The log masses
  distinguish this from a category containing no positive-weight pairs.

From the repository root, build the archive and check the exact file built.
Use a fresh library to verify the installed archive independently of the
source-tree test run.

```sh
export R_LIBS_USER="$PWD/.r-library"
R CMD build .
R CMD check longWR_0.1.0.9000.tar.gz
audit_lib=$(mktemp -d)
R CMD INSTALL --install-tests -l "$audit_lib" longWR_0.1.0.9000.tar.gz
R_LIBS="$audit_lib" Rscript --vanilla -e 'library(longWR); example(longwr_estimate); testthat::test_package("longWR", stop_on_failure = TRUE)'
```

The November 22 review reached the metadata gate in `R CMD check`. The separate
archive installation, help example, and 298 test expectations passed. See
[AI_USAGE.md](AI_USAGE.md) for the environment warning and remaining metadata.

### Check approved package metadata

Use the maintainer-approved identity in `Authors@R` with roles `aut` and
`cre`. Set `URL` and `BugReports` to the repository and its issues page.
Keep the repository's GPL-3 text in LICENSE and use `License: GPL-3` in
DESCRIPTION. Regenerate help before building so the package overview picks
up the maintainer and links.

```sh
export R_LIBS_USER="$PWD/.r-library"
Rscript --vanilla -e 'roxygen2::roxygenise()'
R CMD build .
check_dir=$(mktemp -d)
R CMD check --as-cran --output="$check_dir" longWR_0.1.0.9000.tar.gz
```

On this Mac the HTML check used HTML Tidy 5.8.0 on PATH and V8 in the local
validation library. Read `00check.log` in the resulting check directory and
the expectation count in `tests/testthat.Rout`. The approved-metadata run
resolved the earlier missing-field error. Its two remaining notes are
documented in [AI_USAGE.md](AI_USAGE.md).

### Profile the direct estimator before changing its loop

Use the pre-audit commit `dc62307` as the reference. Compare whole result
lists, including counts, statuses, and reasons. Create the same data and
weights for both implementations and keep data generation outside the timed
calls. The following R commands reproduce the audit from the repository root.

```r
source("R/schema.R")
source("R/longwr_estimate.R")
ref <- new.env()
old_source <- system2("git", c("show", "dc62307:R/longwr_estimate.R"), stdout = TRUE)
eval(parse(text = old_source), envir = ref)

measure <- function(f, d, w) {
  invisible(f(d, w))
  elapsed <- replicate(7, system.time(f(d, w))[["elapsed"]])
  path <- tempfile()
  Rprofmem(path)
  f(d, w)
  Rprofmem(NULL)
  entries <- grep("^[0-9]+ ", readLines(path), value = TRUE)
  bytes <- as.numeric(sub(" .*", "", entries))
  c(median_seconds = median(elapsed), cumulative_MiB = sum(bytes) / 2^20)
}

for (n in c(1000, 4000, 8000)) {
  set.seed(615)
  d <- data.frame(id = seq_len(n), A0 = rep(c(0, 0, 1, 1), n / 4),
                  A1 = rep(0:1, n / 2), L0 = rnorm(n), L1 = rnorm(n),
                  B = rbinom(n, 1, .3), Y = sample(-8:8, n, TRUE))
  w <- exp(rnorm(n))
  stopifnot(identical(ref$longwr_estimate(d, w), longwr_estimate(d, w)))
  print(rbind(before = measure(ref$longwr_estimate, d, w),
              after = measure(longwr_estimate, d, w)))
}
```

Each fixture assigns one quarter of the cohort to each observed history.
Measurements include schema validation, numeric weight alignment, and the
direct estimator. Rprofmem records cumulative allocations during a separate
warmed call. Peak live memory is a different quantity.

| Cohort size | 11 × 00 pairs | Median elapsed, before → after | Cumulative R allocations, before → after |
| ---: | ---: | ---: | ---: |
| 1,000 | 62,500 | 3 → 2 ms | 5.4 → 3.9 MiB |
| 4,000 | 1,000,000 | 27 → 18 ms | 82.1 → 59.0 MiB |
| 8,000 | 4,000,000 | 109 → 77 ms | 324.5 → 232.5 MiB |

These timings describe R 4.4.1 on this arm64 Mac. For a fixed schema,
validation and ID alignment scan the full cohort in linear time. Adding
mapped covariates adds finite-value scans for each column. The current schema
helper also searches input column names for each mapping and grows a
data frame one column at a time. At 1,000 rows, schema validation alone took
about 0.1 ms with one baseline covariate and 1.5 ms with 100.

The pair loop still visits every 11/00 pair. It computes the binary comparison
masks once for each possible treated event value. Each treated subject's
score determines the remaining comparisons. Direct summation of the three
categories retains small masses, and writing contributions at their original
row indices preserves their order for the final sums. The live pair workspace
grows with the two regime sizes. Cumulative allocations grow with the number
of pairs as R creates and releases per-subject vectors.
