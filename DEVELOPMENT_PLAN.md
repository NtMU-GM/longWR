# longWR development plan

Work through one milestone at a time. Run tests after each implementation step
and record commands, results, discrepancies, and decisions in
[AI_USAGE.md](AI_USAGE.md). Use [SPEC.md](SPEC.md) as the source of truth for
the 11 versus 00 estimand, scope, and release gates.

| Phase | Target | Acceptance criteria |
| --- | --- | --- |
| 0. Environment and scaffold | Nov 22 | Inspect R, Git, and development packages. Resolve missing dependencies and verify the namespaces. Initialize local Git, package metadata, documentation, and a testthat harness. Install and load the scaffold in a fresh R process and run the smoke test. |
| 1. Data contract and direct estimator | Nov 24–30 | Validate mapped columns, IDs, independent subject rows as a documented input assumption, and required values. Test the direct prioritized comparison with the hand-worked WR of 4 and normalized masses of 12/21, 3/21, and 6/21. Cover ties, zero win or loss, absent regimes, invalid weights, scaling, row order and ID alignment, and large weights. Return the specified statuses and regime and pair counts. |
| 2. Simulator and sequential weights | Nov 24–30 | Generate reproducible synthetic data and known observed-treatment probabilities for all specified scenarios. Fit both logistic models over all histories, reconstruct stage and cumulative weights, and preserve ID alignment. Exercise all four histories in a working example with custom column mappings. Test model diagnostics, including warning and failure paths. |
| 3. Reference checks, diagnostics, and simulation validation | Dec 1–7 | Compare same-data stage and product weights with WeightIt and selected-regime point estimates with WINS using documented conventions and tolerances. Verify history-specific balance and overlap, SMD and ESS arithmetic, and descriptive plots. Generate truth under independent interventional draws, verify the analytic null and shared truth where applicable, and report estimator performance, Monte Carlo precision, failures, and denominators for all scenarios. |
| 4. Documentation and reproducible study | Dec 8–13 | Document the six public functions, assumptions and estimand, custom-mapping example, and end-to-end vignette with the manual WeightIt and WINS workflow. Record scenario settings, seeds, versions, and runtimes for the final study. Verify examples, installation, testthat, and package checks across supported platforms. |
| 5. Release readiness | Dec 14–17 | Confirm package name availability, current CRAN policies, approved attribution, a real maintainer email, and the license. Build the source tarball and run `R CMD check --as-cran` with no unexpected errors or warnings. Document check results and outstanding notes. Prepare final deliverables and the 5–10 minute video. Publish or submit only with explicit approval. |

The checkpoint is due Nov 23 at 11:59 p.m. Eastern and calls for actual repository
status, a repository link, the proposed change, a feedback request, and a video
plan. The final deliverables are due Dec 17 at 3:30 p.m. Eastern.

After the direct estimator passes its validation gates, consider exact sorted
counting and benchmark equivalence and runtime before enabling it. Treat
bootstrap inference as optional and contingent on coverage validation. Follow
the scope and deferral conditions in the specification.

## Milestone status · November 22, 2026

Phase 0 is complete at local commit `16e29be`. Phase 1 passed its estimator
review on November 22. The Section 8 example gave WR 4 and WINS agreed on
two datasets with weighted and crude analyses. The review corrected ambiguous
ID matching, status precedence, and probability rounding. Verification of the
source archive recorded 298 passing expectations and no failures or skips.
The maintainer approved the author, contact details, GPL-3 license and public
repository URLs. The subsequent macOS arm64 `R CMD check --as-cran` completed
with zero errors, zero warnings, and two notes covering CRAN incoming
(new submission and development version) and external clock verification.
Both manuals and all 298 test expectations passed. Repeat the check on the
release version and complete the planned cross-platform checks before release. Reproduction commands are in [AGENTIC_TUTORIAL.md](AGENTIC_TUTORIAL.md).

Phase 2 is pending. Its first integration check should pass the sequential
weight object's full-cohort IDs and cumulative weights into the Phase 1
estimator and verify row-permutation invariance.
