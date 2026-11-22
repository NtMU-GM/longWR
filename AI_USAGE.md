# AI usage log

Record the prompt, agent actions, commands and observed results, failures and
recoveries, and any decisions requiring student review for each milestone.

## 2026-11-22 · Phase 0

### Prompt

> Read AGENTS.md and SPEC.md completely.
>
> Execute Phase 0 only:
>
> 1. Inspect the development environment, including R, Git, and required R packages.
> 2. Identify and resolve missing dependencies.
> 3. Initialize the longWR R package structure.
> 4. Initialize the local Git repository.
> 5. Create DEVELOPMENT_PLAN.md with milestones and acceptance criteria.
> 6. Initialize AI_USAGE.md to document the agentic coding process.
> 7. Verify that the initial package can be loaded successfully.
>
> Do not implement any statistical methods yet.
> Do not push to GitHub.
>
> Report completed tasks, verification results, remaining issues, and
> recommended next steps before proceeding to Phase 1.

### Actions and decisions

- Codex read both project instructions in full and inspected the workspace and
  adjacent project files. The original proposal document is in the parent
  directory. No legacy package checkout was identified there.
- Initialized the local repository on `main` and selected `0.1.0.9000` as the
  scaffold version ahead of the specification's 0.1.0 release target.
- Added package-level documentation and a namespace smoke test. Author and
  maintainer fields await approved attribution and contact details. The
  license field is provisional pending a license decision.
- Used a Git- and build-ignored `.r-library/` for additional R dependencies.

### Environment and verification

- Inspected R and Rscript 4.4.1 (macOS arm64), Git 2.51.0, and Pandoc 3.12.
  The existing R library provided stats 4.4.1, roxygen2 7.3.2, ggplot2 4.0.0,
  knitr 1.51, rmarkdown 2.30, and pkgload 1.4.0.
- The sandbox blocked writes to `.git` and the initial package index was
  inaccessible. With escalation, `git init --initial-branch=main` succeeded
  and CRAN installed testthat 3.3.2, WeightIt 1.6.0, WINS 1.5.1, and their
  indexed dependencies. CRAN's binary index omitted gsl for R 4.4. Installed
  the [official macOS arm64 binary for gsl 2.1-8](https://cloud.r-project.org/bin/macosx/big-sur-arm64/contrib/4.4/gsl_2.1-8.tgz)
  directly into `.r-library/`.
- Loaded every inspected R namespace and verified that
  `WeightIt::weightitMSM` and `WINS::win.stat` are available. Statistical
  reference comparisons are scheduled for Phase 3.
- `R_LIBS_USER="$PWD/.r-library" R CMD INSTALL --install-tests .` succeeded.
  In a fresh `Rscript --vanilla` process, `library(longWR)` loaded version
  0.1.0.9000. The first smoke test failed because `getNamespaceName()`
  returned a named character vector. After removing the name before
  comparison, the installed test run reported one pass and zero failures.
  `testthat::test_local(".", reporter = "summary")` also passed. R emitted
  a startup warning that testthat was built under R 4.4.3.
- `R CMD build` succeeded in a temporary directory. The source archive
  contained the package files and tests and excluded the local R library
  and project-only records.
- Confirmed the new Git repository is on `main` with no commits or remotes.

### Student review

Student review has not yet been recorded. The next review should confirm that
the milestone gates match the specification and that the local test commands
are reproducible. The user will need to supply approved author and maintainer
details before release.

## 2026-11-22 · Phase 1

- Codex (GPT-6.2-astra) worked from the user's request to checkpoint the
  scaffold, implement shared schema validation and the direct weighted
  estimator, test the Section 8 example, generate help, and stop after Phase 1.
- Read AGENTS.md, SPEC.md, and DEVELOPMENT_PLAN.md. Verified the Git exclusions
  for the local library, package tarball, check directory, and R history.
  Committed the scaffold locally as `16e29be` before implementing the module.
- Validated all mapped rows before selecting regimes. Chose positional numeric
  weights with optional ID names and ID matching for a weight object containing
  `id` and `w`. Zero-weight subjects still contribute to observed counts.
  Implemented separate log-scale mass sums for wins, losses, and ties to retain
  small categories and distinguish structural zeros from floating-point limits.
- Ran the schema tests first, reran the source suite during implementation,
  regenerated the function help and namespace with roxygen2, and installed
  with tests. Roxygen initially skipped the hand-authored package overview.
  Converted it to generated documentation and reran roxygen2 successfully.
- The installed help example returned 4. WINS 1.5.1 reproduced the weighted
  WR of 4, crude WR of 2, and directional probabilities on the Section 8 data.
  The final installed suite reported 153 passing expectations, 0 failures,
  0 test warnings, and 0 skips. R separately reported that testthat was built
  under R 4.4.3 on this R 4.4.1 installation.
- The tutorial records reproducible commands and review exercises. Independent
  student review of this implementation is pending.

### Phase 1 review before Phase 2

The user asked Codex (GPT-6.2-astra) to audit the existing estimator, add
independent and boundary tests, improve comments and help, correct verified
defects, and commit Phase 1 locally. Student review of the changes is pending.

- Re-read all three governing documents. Traced 11/00 selection, binary-first
  comparison, per-regime normalization, category probabilities, and WR against
  sections 2.4 and 8. The original 153 expectations passed before edits.
- Reproduced duplicate weight fields silently selecting the first vector and
  distinct numeric IDs printing as the same weight name. Reject ambiguous
  names and lossy mixed ID conversions while retaining exact numeric keys.
  Also reject a matrix of factor IDs before converting factor levels to text.
- Reproduced an invalid weight masked by an absent regime and a positive
  probability underflow masking a structural zero. Validate all supplied
  weight values first and preserve a one-sided status with the underflow in
  its reason. Renormalize the three log masses as a partition to correct an
  observed all-tie probability of 1.0000000000000002. The first round of
  regression tests recorded nine failed expectations before these fixes.
- Verified crude WR 2 and weighted WR 4 for the manual fixture. WINS 1.5.1
  agreed for both methods on two fixtures, including interleaved arms of
  unequal size. WINS checks use digit 12 and tolerance 1e-10. A separate
  expanded-frequency comparison checked all 81 assignments of three outcome
  levels to four subjects. Tested a pair count above 32-bit integer range
  using a zero-weight regime to avoid enumerating billions of pairs.
- Generated roxygen help, ran the source suite, built the tarball and installed
  it into a temporary library. A path assertion initially compared the macOS
  temporary-directory alias with its resolved path. The rerun compared both
  resolved paths and verified the installed copy. Rd checks, documentation
  consistency and code-usage checks reported no issues. The installed example
  returned 4. The installed suite reported 298 passes, 0 failures, 0 test
  warnings, and 0 skips. R 4.4.1 separately warned that testthat was built
  under 4.4.3.
- Both the preliminary check with `--no-manual` and the final standard
  `R CMD check` stopped with one missing-metadata error for Author and
  Maintainer. License remains TBD. Verification was local on macOS arm64.
- The project-library reinstall encountered a leftover installation lock with
  empty staging directories. Moved the lock aside and installed the verified
  tarball locally. The project-library test run also passed all 298 expectations.

### Approved metadata and CRAN-style check · November 22, 2026

The maintainer approved the author name, email, GPL-3 license and existing
public repository. Codex (GPT-6.2-astra) updated DESCRIPTION, regenerated the
package overview, and verified the installed Author, Maintainer, License, URL
and BugReports fields. The checkout's LICENSE matches the public repository's
Git blob `f288702d2fa16d3cdf0035b15a9fcbc552cd88e7`. R distributes the GPL-3
text, so the package archive declares the standard license in DESCRIPTION.

The first online `R CMD check --as-cran` completed with four notes. The macOS
system Tidy from 2006 rejected HTML5 markup and the check directory contained
a residual installation lock. Installed HTML Tidy 5.8.0 via Homebrew and V8
8.0.1 in the local R library for documentation checks, then checked the same
tarball in a fresh directory. The PDF and HTML manuals, examples, installation
and 298 test expectations passed, including WINS checks.

The final macOS arm64 check under R 4.4.1 reported 0 errors, 0 warnings and
2 notes. CRAN incoming reported a new submission and the large component in
the planned development version 0.1.0.9000. Keep the planned 0.1.0 version for
release. R could not verify current time against its external service. A
separate inspection of all 18 archive entries found zero future timestamps
relative to the local clock. The timestamp check was enabled on both runs.
