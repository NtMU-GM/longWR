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
