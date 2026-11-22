# longWR — Agent-Ready Project Specification

**BIOSTAT 615 Final Project | Track B: R statistical software package**  
**Author:** SG  
**Revision:** November 22, 2026 (supersedes the October 26 IPTWWinDiag design for future development; retain the original proposal as a historical artifact)  
**Provisional package name:** `longWR`; initial release target 0.1.0 (verify name availability before submission)  
**Title:** Estimating Win Ratios Under Longitudinal Static Treatment Regimes Using Inverse Probability Weighting  
**Final submission:** December 17, 2026, 3:30 p.m. Eastern  
**Status:** Revised design, not a statement of implemented features or completed validation. Existing repository progress must be inspected before changes.

## 1. Goal, users, and rationale

Build a small, installable R package for estimating a marginal, prioritized-outcome win ratio comparing two sustained treatment strategies in fully observed observational data with two treatment decisions. A user can analyze their own compatible dataset, understand overlap and treatment-history-specific diagnostics, and reproduce a simulation comparing estimates with the known interventional target. The package implements established longitudinal inverse-probability weighting and weighted pairwise comparison; it does not claim a new statistical theory or clinical decision rule.

The professor's feedback identifies overlap with WINS, limited incremental usefulness, and CRAN publication as a desirable goal. The revised package addresses this by making longitudinal regime-specific inference the main subject rather than reproducing a subset of WINS. The users are methodological biostatisticians, observational researchers, and students working with repeated treatment decisions and ordered terminal endpoints. The central example is a binary adverse event (lower is better) followed by a continuous functional score (higher is better).

### 1.1 Current software landscape (documentation audit, November 22, 2026)

| Software | Documented strengths | Relevance and boundary |
|---|---|---|
| WINS | Prioritized mixed outcomes, win statistics, user-supplied IPTW, IPCW including time-dependent censoring covariates | Can evaluate a compatible weighted two-arm comparison after regime selection; its documented time-dependent covariates for CovIPCW address censoring, not a dedicated end-to-end static longitudinal treatment-regime analysis. |
| WeightIt | `weightitMSM()` estimates weights for longitudinal treatments | Can calculate the same sequential weights. Use as an independent validation baseline; do not claim weight estimation itself is novel. |
| cobalt / WeightIt balance workflow | Covariate balance diagnostics for longitudinal weights | Existing diagnostics are valuable; longWR supplies targeted regime counts, history-specific balance, and outcome-estimator validation. |
| causalWins | Matching, distributional regression forests and efficient influence function estimators for its causal win-ratio framework | Distinguish marginal interventional distributions here from conditional/individual-effect proxy estimands; no claim that it lacks every longitudinal extension without further review. |
| WinRatio / BuyseTest | Generalized pairwise comparisons, prioritized outcomes, inference, and broader endpoint methods | Mature comparison software; not competitors on endpoint breadth. |
| winnify | WINS wrappers, formula interface, endpoint contribution visualization | General usability and plotting are no longer sufficient differentiators; released November 13, 2026. |

In a targeted search of package documentation and literature, no dedicated turnkey implementation exactly matching this narrowly defined two-decision workflow was identified. This is evidence for a useful software niche, not proof that no such method or software exists. In fact, `WeightIt` + appropriately subsetted `WINS` can reproduce the point estimator. The package must demonstrate, rather than merely assert, added value: a coherent, explicit estimand; data contract; correct sequential fitting on all observed histories; fixed-regime selection; history-specific balance; interventional truth simulation; and, if validated, a faster weighted pair-counting algorithm. Include a reproducible comparison of the manual two-package workflow against `longWR` in the vignette. Report measured speed and useability differences rather than claiming superiority over all packages. No copying of other packages' source.

## 2. Scientific target and identification

### 2.1 Data-generating order

One independent subject per row. Baseline covariates L0 are measured before binary treatment A0; updated covariates L1 are measured after A0 and before binary treatment A1; endpoints (B,Y) are measured after A1. In observational data, L1 can be affected by A0 and affect both A1 and endpoints. Outcomes need not be repeated measurements. There is no censoring, missingness, clustering, variable follow-up or death-related undefined score in v0.1.0. Do not propose imputation or clinical use for incomplete endpoints.

### 2.2 Outcome comparison and estimand

Let Z = (B,Y). For two outcomes u,v, define h(u,v) = +1 if u.B < v.B, or if their B values are equal and u.Y > v.Y; -1 for the reverse order; 0 if both outcomes are equal. The binary adverse event is always first. No nonzero equivalence margin or arbitrary pairwise kernel in the MVP. Zero and one represent absence and presence of an adverse event, respectively. Continuous scores use an exact zero comparison margin, with larger values better. The intervention regimes are g=(1,1) and h=(0,0). All subjects in the target baseline population are hypothetically assigned to each regime in turn, whether or not they actually followed that regime.

Let G_11 and G_00 be the marginal distributions of the joint potential outcome Z^11 and Z^00. Draw U ~ G_11 and V ~ G_00 **independently**. Define

```
p_win  = P(h(U,V) = +1)
p_loss = P(h(U,V) = -1)
p_tie  = P(h(U,V) = 0)
WR_11,00 = p_win / p_loss, if p_loss > 0.
```

This is a marginal between-regime population contrast; it is not an individual causal treatment effect, a conditional same-baseline contrast, a longitudinal varying-coefficient model, a hazard ratio, or a comparison of outcomes only among the actual adherers. It includes the total effects mediated by L1. The estimand does not require the joint distribution of unobserved potential outcomes for the same person. Win/loss/tie probabilities should accompany a ratio because near-zero loss probabilities can destabilize WR. Potential outcomes under fully specified, feasible treatment strategies must be meaningful.

### 2.3 Assumptions and identification

Assume consistency (including well-defined intervention versions and no interference), sequential conditional exchangeability for the joint endpoint under each regime, positivity at each relevant history, independent subjects, correct temporal measurement, and no informative missingness because complete outcomes are required. Formally, for each static regime a whose prefix is followed:

- Z^a independent of A0 conditional on L0.
- Z^a independent of A1 conditional on A0=a0, L0, L1.
- P(A0=a0 | L0)>0 and P(A1=a1 | A0=a0,L0,L1)>0 almost surely on histories reachable under the corresponding regime.

Define e0(L0)=P(A0=1|L0), e1(A0,L0,L1)=P(A1=1|A0,L0,L1). The observed-history probability factors are q0=e0 for A0=1, otherwise 1-e0; q1 similarly conditional on A1. Set r0=1/q0, r1=1/q1, w=r0*r1. For any bounded function f of the joint outcome and fixed regime a, the identifying relation is

```
E[f(Z^a)] = E[I(A0=a0,A1=a1) * w * f(Z)].
```

The expectation on the right identifies the distribution via f(Z)=I(Z in S). This follows from iterated expectation and sequential exchangeability/consistency, eliminating the treatment assignment factors at t=1 and t=0. Under the assumptions, combining two independently sampled identified marginal distributions identifies p_win, p_loss and p_tie. This establishes the population target; it does not imply that finite-sample estimated weights are unbiased or that an existing variance estimator is valid. The plug-in estimator additionally requires consistent estimation of conditional probabilities (correctly specified logistic models in the intended simulation), finite/adequate weight behavior, and positive loss probability for stable WR inference. Unmeasured confounding and positivity cannot be ruled out by diagnostics alone.

### 2.4 Estimator

Estimate e0 and e1 via separate binomial logistic models **using all subjects across all four histories**, before subsetting to 11/00. Default formulas: A0 ~ baseline covariates; A1 ~ A0 + baseline covariates + updated covariates. No outcome or future variable enters either treatment model. No stabilized weights in MVP. Fit using `stats::glm`, predict response probabilities. Store q0, q1, r0, r1, w and model diagnostics, aligned to unique IDs.

Select subjects I11={i:A0=A1=1} and I00={j:A0=A1=0}. Subjects with histories 10/01 are used for estimating weights and diagnostics but not in the final pair comparison. For each pair form w_i w_j and compare Z_i vs Z_j. Define weighted masses W,L,T by summing that product in each of the three comparison categories. Define S=(sum_11 w_i)*(sum_00 w_j)=W+L+T and estimated probabilities (W,L,T)/S. WR=W/L. This is the Hájek-style plug-in estimator of the two weighted marginal distributions. Do not fit models only within the 11/00 subset; do not recode A1 as baseline treatment or interpret crude adherer comparison causally.

Unweighted comparison uses w=1 among the same regimes. Optional validation comparator deliberately omits L1 from the second treatment model and is labelled misspecified under feedback. Optional weight capping is sensitivity analysis, not guaranteed estimation of the original target; it is off by default. No clipping or trimming behind the user's back. Constants multiplying all weights within one regime cancel from the ratio and probabilities. To avoid overflow, normalize each selected regime's weights separately before calculating probability masses; keep raw weights for diagnostics and report normalized masses as such. Direct and sorted algorithms must match the same probabilities and ratio. Never silently replace zero loss or all ties: p_loss=0,p_win>0 yields Inf and `zero_loss`; p_win=0,p_loss>0 yields 0 and `zero_win`; both zero yields NA and `all_ties`; an absent regime or no positive total weight yields NA and `empty_regime`/`invalid_weights` with a reason. Return explicit statuses and report nonfinite estimates.

## 3. Scope and data contract

| Component | v0.1.0 |
|---|---|
| Design | Two binary decisions, one row per independent subject; four observed histories |
| Contrast | Always treated 11 vs never treated 00, predefined; all histories in models |
| Covariates | One or more finite numeric/binary baseline variables, one or more finite numeric/binary updated variables measured before A1 |
| Outcomes | Final binary adverse event B and numeric score Y; B first, Y breaks ties |
| Missing data | Explicitly reject missing/nonfinite values in required fields |
| Treatment model | Main-effects logistic regressions, unstabilized weights |
| Inference | Point estimates, diagnostics, simulation bias; bootstrap only if validated as optional extension |

Support real compatible data, not just simulator output. Default column mapping `id`, `A0`, `A1`, `L0`, `L1`, `B`, `Y`. Provide explicit `id`, `treatment`, `baseline`, `updated`, `outcomes` arguments to map real column names; use a common validation helper and `reformulate` safely. Baseline and updated lists must not overlap and may not include treatments, IDs or outcomes. No arbitrary user formulas in MVP; users may supply precomputed legitimate transformations as mapped covariate columns if measurement timing is valid. Detect nonunique/missing IDs, wrong binary coding, empty decision arms, invalid types, nonfinite values, rank deficiency and GLM convergence/separation indicators; report model warnings and very small probabilities rather than silently fixing them. `glm` convergence is not proof of adequate overlap. Require both observed A0 levels and both observed A1 levels for fitting; missing cells of the 2x2 history table are flagged, and an absent target regime prevents its estimate. Do not require all four histories for all valid dataset-level estimates. Never drop subjects silently. Build internal fresh data with safe canonical column names for formulas if necessary. For incompatible input, give informative errors. For valid but nonestimable analyses, return documented failure statuses. Preserve input row order and align any weight object by ID; when numeric external weights are accepted, require exact row order and document that the caller supplies valid weights.

## 4. Public API (six functions)

Keep the interface compact and stable; document the actual argument names and every return field. Standardized schema by default, with explicit mappings shared by weights, estimate and diagnostics. A single example using externally formatted synthetic data must prove the mappings work.

| Export | Required behavior |
|---|---|
| `longwr_simulate(n=1000, scenario="feedback", seed=NULL)` | Return wide subject-level data, true observed probabilities for simulation verification, DGM metadata. A scenario may be named or a validated parameter list. |
| `longwr_weights(data, id="id", treatment=c("A0","A1"), baseline="L0", updated="L1", outcomes=c("B","Y"))` | Fit both logistic models on whole data; return aligned probabilities and stage/cumulative weights, model summaries, status and warnings. |
| `longwr_estimate(data, weights=NULL, ...)` | Weighted or unweighted point estimate (NULL means unweighted), win/loss/tie probabilities, pair counts and regime sizes, status. Accept validated `longwr_weights` object or aligned numeric vector. `...` here denotes shared schema arguments; implement them explicitly. |
| `longwr_diagnostics(data, weights, ...)` | Return tidy stage- and history-specific balance/overlap tables, all four trajectory counts, cumulative weight/ESS summaries, and flags. |
| `longwr_validate(scenarios=NULL, n=1000, reps=20, truth_pairs=100000, seed=615)` | Run reproducible simulation with reference truth, record naive, oracle, fitted sequential IPTW and omitted-L1 comparator; return replicate data, summaries, diagnostics, configuration, truth precision and failure counts. Allow tiny smoke runs. |
| `plot_longwr(object, view=c("balance","overlap","weights","performance"))` | A small set of documented plots with appropriate object checks (base graphics or ggplot2; avoid dependency bloat). |

Illustrative workflow (must be executable as documented before release):

```r
library(longWR)
d <- longwr_simulate(n = 1000, scenario = "feedback", seed = 42)
w <- longwr_weights(d)
longwr_estimate(d)           # crude, same 11/00 histories
longwr_estimate(d, w)        # sequential-IPTW marginal regime WR
dg <- longwr_diagnostics(d, w)
dg$history_counts
plot_longwr(dg, view = "balance")
v <- longwr_validate(scenarios = "feedback", n = 500, reps = 5,
                     truth_pairs = 10000, seed = 615)
v$summary
```

## 5. Diagnostic design

Diagnostics are descriptive, not a test of causal identification. All tables identify their treatment time, comparison, weighting convention, quantities and sample sizes.

1. Count subjects in 00,01,10,11 and show target-regime selection fraction. Report q0 and q1 ranges/quantiles and extreme observed-probability fractions; also show propensity score overlap by actual treatment decision at each stage and within A0 history for A1. Flag small groups and extremely low observed treatment probabilities; no arbitrary threshold is a guarantee of positivity.
2. At t=0, compare baseline variables across A0=1 versus A0=0 with unit weights and stage-0 inverse weights r0 using all observations. Do not compare L1 at t=0.
3. At t=1, compare baseline and updated covariates across A1=1 versus A1=0 separately within A0=0 and A0=1. Report raw unweighted SMD, pre-stage-1 SMD with r0 and post-stage-1 SMD with r0*r1. Use the same pre-weighting, stratum-specific pooled unweighted SD denominator (mean absolute difference and a status when variance is zero; explicitly define 0/0 as zero only when means equal). Binary covariates may use the same pooled SD convention. Missing groups remain labelled nonestimable. Never demand L1 balance across 11 vs 00: A0 may causally affect L1.
4. At final regime level, compare baseline L0 in weighted versus crude 11/00 and against the unselected full baseline sample (report target mean, each regime mean and differences). Do not balance away genuine post-treatment mediator differences.
5. Show stage weights r0, r1 and cumulative w quantiles, max, proportion above configurable descriptive threshold; ESS=(sum w)^2/sum(w^2) per target regime and optionally all four histories. ESS cannot exceed nonzero-weight n aside from roundoff. Report separation/rank deficiency/warnings and nonfinite weights. For each user plot, show exactly what was weighted; never label weight truncation corrective.

## 6. Reproducible simulation and known truth

Use only synthetic data. Draw independent L0,U1,epsilon ~ N(0,1); treatment assignment Bernoulli with separate independent draws; endpoint Bernoulli draw independent of epsilon given its history. Example DGM:

```
L0 ~ N(0,1)
A0 ~ Bernoulli(expit(alpha0 + alphaL*L0))
L1 = deltaL*L0 + deltaA*A0 + U1
A1 ~ Bernoulli(expit(eta0 + etaA*A0 + etaL0*L0 + etaL1*L1))
B  ~ Bernoulli(expit(beta0 + betaL0*L0 + betaL1*L1 + betaA0*A0 + betaA1*A1))
Y  = gamma0 + gammaL0*L0 + gammaL1*L1 + gammaA0*A0 + gammaA1*A1 + epsilon
```

Initial parameters, configurable and subject to empirical calibration: alpha0=eta0=0; alphaL=0.6; etaA=0.4, etaL0=0.3, etaL1=0.7; deltaL=0.5, deltaA=0.6; beta0=-1, betaL0=0.5, betaL1=0.6, betaA0=betaA1=-0.5; gamma0=0, gammaL0=-0.4, gammaL1=-0.5, gammaA0=gammaA1=0.5. L1 represents risk burden. Inspect whether overall effect is beneficial; do not assume from direct coefficients alone. Initial scenarios:

| Scenario | Change from feedback DGM | Purpose |
|---|---|---|
| randomized | alphaL=etaA=etaL0=etaL1=0 | Known 0.5 probabilities; no treatment-selection confounding |
| null | deltaA=betaA0=betaA1=gammaA0=gammaA1=0 | True WR=1 even in presence of confounding; important to disable treatment-mediated effects too |
| feedback | As above | Treatment-confounder feedback and correctly specified sequential model |
| poor_overlap | alphaL=1.5, etaL0=0.7, etaL1=1.5, etaA=1.0 | Practical positivity and variability stress test |

Verify achieved history counts, probability distributions and endpoint effects in a pilot; adjust transparently if pathological. The first three should have adequate observed histories in large samples. Optional nonlinear-treatment-model scenario adds a quadratic term to the true A1 logit while fitting a main-effects model; label it as misspecified. Do not equate observed sample overlap with proof of population identification.

For causal truth, explicitly intervene: draw fresh independent L0, U1 and endpoint errors, set A0=A1=1, generate L1 under A0=1, then Z under regime 11. Generate a separate independent subject for 00 with its own L0/errors and L1 under A0=0. No observed-treatment filtering is used. Repeat M independent pairs; compute truth by direct win/loss probabilities (O(M), not M squared). Exact null truth=1 if both regimes generate identical distributions and loss probability>0. Use distinct truth and estimation seeds; default M=100,000 for quick runs, final benchmark M>=1,000,000 or verified comparable precision; document MC error via batches or multinomial delta method on log-WR when probabilities positive. Cache truth across scenarios sharing all outcome and covariate DGM parameters; treatment model differences alone do not affect interventional truth. If a truth is estimated rather than analytic, report uncertainty. Do not compare paired within-subject counterfactuals.

Estimator comparisons per replication: crude 11/00, oracle true sequential probabilities, fitted sequential IPTW, and fitted weights omitting L1 in the second model (deliberately misspecified in feedback scenarios; evaluate rather than assume its bias). The randomized scenario is a sanity check, not a requirement that finite-sample estimated-weight and crude estimates be identical. Report bias and RMSE relative to interventional WR, log-scale bias/RMSE among strictly positive finite estimates, empirical SD, median/IQR, failure and zero/infinite rates, arm ESS and overlap. Include Monte Carlo SE for bias (SD/sqrt(valid-reps)), label summaries conditional on valid estimates and report denominators. Store all requested replication outcomes including model errors. Use small examples in tests and CRAN examples; run a separate final reproducible study (e.g. n=1000 and n=3000, 200--500 reps per scenario after profiling). Record actual runtime, seeds, parameter settings and package versions. Do not tune or cherry-pick seeds to obtain desirable behavior. Show results even when fitted weighting is variable or biased under poor overlap; simulation is a check, not proof of general performance. No coverage or type-I error claims for point-only MVP.

## 7. Computing contribution and optional uncertainty

P0: implement a transparent direct O(n11*n00) reference with memory-conscious chunks or loops; do not allocate full pair matrices for large samples. Unit weights and arbitrary positive subject weights use the same comparison. Report pair count as a number large enough to avoid integer overflow; use normalized probability accumulation. P1 high priority: implement exact sorted weighted lexicographic counting for this specific comparison (B ascending, Y descending). Group identical outcome keys, sweep ordered ranks, multiply the treated mass at each key by the cumulative control mass strictly worse (wins) and strictly better (losses), and equal-key control mass (ties). Use independent prefix/suffix sums to avoid catastrophic cancellation for highly unequal weights. This gives O(n log n) sorting and O(n) sweep with O(n) storage, where n=n11+n00, assuming fixed two endpoints and weights. It is exact up to floating-point arithmetic, not a pair subsampling approximation. Validate against direct computation before enabling. Benchmark n at several realistic scales with same data/weights/conventions; report wall clock and optional memory, repeated timings, and tolerance, using `WINS` point estimates as an external comparison when practical. Keep dependencies minimal; no Rcpp unless justified by measured bottleneck. Do not claim a new algorithm or blanket speed superiority; distinguish estimator-only benchmark from full pipeline timing. If fewer than two weeks remain and P0 validation is incomplete, defer optimization.

P1 optional: subject-level nonparametric bootstrap resampling entire rows from full cohort, refitting both treatment models, reselecting histories and recomputing WR in every draw. Reassign bootstrap row IDs; do not resample pairs or only adherers; correctly handle replicates with missing regime or separation. Use a documented percentile interval on log-WR only when all validity requirements met, transform back; report requested and usable replicates, failure frequency and limitations. Do not present interval as validated by default until simulation coverage with MC precision is evaluated across adequate-overlap scenarios. If insufficient time, omit inference entirely. WINS inference for supplied weights is not a verified longitudinal estimated-weight variance procedure. No inferential output copied from WINS.

## 8. Mandatory verification and release gates

Write tests before optimizing. Include:

- Hand-computable pair examples: binary priority overrides Y; exact ties; arbitrary unequal weights; normalization; zero wins/losses, all ties, absent regimes; swap 11/00 and check reciprocal when finite and positive. For example 11: `(B=0,Y=1,w=2)`, `(B=1,Y=4,w=1)`; 00: `(B=0,Y=1,w=3)`, `(B=1,Y=2,w=4)` gives raw win mass 8+4=12, loss 3, tie 6, total 21, WR=4. Verify by independent manual arithmetic and exact normalized probabilities 12/21, 3/21, 6/21.
- Unit weights equal crude; scaling within each group cancels; row permutations and correctly ID-realigned weights invariant. Robust large weights, repeated scores, extremely small loss mass, no false ties due to subtraction.
- Test stage probabilities against manually specified values; reconstruct q0/q1 and product; ensure switchers remain in both fitted models. Compare estimated weights against `WeightIt::weightitMSM(list(A0~L0, A1~A0+L0+L1), method="glm", stabilize=FALSE)` on same fully observed data and identical formula/model settings. Investigate discrepancies and numerical tolerance, not just ratios. Optional tests skip when package unavailable.
- Test `WINS::win.stat()` on selected 11/00 subjects as two arms, mapped `id,arm,Y_1,Y_2`, `ep_type=c("binary","continuous")`, `np_direction=c("smaller","larger")`, `priority=c(1,2)`, `tau=c(0,0)`, `method="iptw"`, same aligned weights; verify actual API convention and compare point estimates only (handle output rounding via `digit` or justified tolerance). Also check unadjusted. Do not use WINS results as truth for a causal estimand; they validate weighted arithmetic, not identification.
- Test custom mappings, invalid binary coding, nonunique IDs, missing/nonfinite data, nonconvergence/warnings, rank deficiency, no usable weights, and empty regimes. All failures must be intelligible and counted by simulations. Input covariates cannot overlap forbidden columns. Known simulated treatment probabilities reproduce manual weights.
- Diagnostics: hand-calculated ESS and SMD; t=1 within each A0 history, pre r0 vs post r0*r1; baseline differences, absent cells and constant covariates. Confirm intervention can preserve L1 differences across 11/00 even with good weighting.
- Interventional truth: independent regime draws, no selection on observed history; analytic null truth; overlap changes do not change truth; consistency with large-cohort oracle simulation within MC uncertainty. Validate recovery in well-specified scenarios by reporting bias and uncertainty, not enforcing artificial finite-sample unbiasedness. Same seed gives same results; raw failure accounting verified.
- If sorted algorithm ships, compare thousands of small randomized cases against direct reference, ties, weight scales, edge cases, and reasonable tolerances. Benchmark speed only after verification.
- Final package: install clean checkout, `testthat` pass, short examples run, no unexpected warnings/errors in `R CMD check --as-cran`; check Windows/macOS/Linux via CI or appropriate builders, accurately document actual checks. No claims of completed tests or CRAN acceptance without evidence.

## 9. Package engineering, release and examples

Use base R plus `stats`; `testthat`, `roxygen2`, optional `ggplot2`, `WeightIt`, `WINS`, `knitr`, `rmarkdown` as appropriate. Validation-only dependencies in Suggests, never needed to compute the core analysis. Keep a conventional package layout (`DESCRIPTION`, `NAMESPACE`, `R/`, `man/`, `tests/testthat/`, `README.md`, `LICENSE` if required, `NEWS.md`, `vignettes/`, `.github/workflows/`, `AI_USAGE.md`, `SPEC.md`). Choose a compatible open-source license and credit references/dependencies. `Authors@R` uses the user's approved attribution and a real maintainer contact supplied by the user; do not invent contact information. Provide installation from GitHub, quick-start real-compatible input example, reference explanations, pairwise definition, assumptions/limitations, diagnostics and end-to-end simulation vignette. `AI_USAGE.md` records actual agentic prompts, failures, code verification and student understanding. Keep examples and default tests short, deterministic, offline-capable, free of network calls, persistent writes or unnecessary CPU. Seed handling must be documented and reproducible. Publish public GitHub repository as course requires; do not create a second repository without user approval. Preserve the original proposal and reconcile changes in existing repository history.

CRAN readiness is an explicit deliverable: verify name availability/current policies, build source tarball, run `R CMD check --as-cran`, address issues, perform relevant Windows and macOS checks, provide submission comments for legitimately unavoidable notes. Target formal submission by Dec 14--16 if P0 passes and the maintainer approves. Submission requires real maintainer identity and confirmation; do not submit automatically or claim CRAN acceptance before confirmation. Acceptance by the deadline is outside the author's control. If blocked, release an installable GitHub package with documented check results and a concise explanation. Do not sacrifice correctness for submission. Reference CRAN current policies and checklist below.

## 10. Migration, checkpoint, milestones

Inspect current IPTWWinDiag repo and tests (do not assume implementation status). Preserve its direct weighted comparison code when correct, reuse diagnostic helpers with revised longitudinal definitions, keep test fixtures and logging. Rework treatment model, simulator, target estimand, history selection, reference truth, scenario analysis and README. Legacy baseline behavior can remain internal/reference or on historical branch; do not expose a second full baseline package API in this release.

| Deadline | Definition of done |
|---|---|
| Nov 23, 11:59 p.m. ET | Push actual current code (no false progress claims). Submit checkpoint with current steps/status, proposed change, feedback request, 5--10 minute video plan and repo link. Course checkpoint grades completion, not amount of progress. Ask professor if the two-stage dedicated workflow offers sufficient utility, with speed benchmark as priority extension. |
| Nov 24--30 | Correct data schema, two-stage simulator and weights, identification explanation, tested direct WR, working example with all four histories. |
| Dec 1--7 | WeightIt/WINS arithmetic checks, interventional truth and MC experiment, diagnostics, failure reporting. Implement sorted algorithm only after P0 tests pass; profile. |
| Dec 8--13 | Stabilize API, documentation and vignette, CI/package checks, reproducible final study. Optional bootstrap only if time and validation permit. |
| Dec 14--17 | CRAN submission-ready bundle and submission attempt if approved, GitHub release, final deliverables, AI_USAGE.md and 5--10 minute video. Final due Dec 17 at 3:30 p.m. ET. |

P0 includes the six public functions, external dataset analysis, tests, Monte Carlo validation, docs, installability and CRAN-ready review. P1 priority: sorted exact algorithm and benchmark; then optional validated bootstrap; formal CRAN submission is the professor-requested release target, not dependent on optional features. P2/out of scope: general T>2, dynamic regimes, multiple treatments, censoring, death-related truncation, repeated terminal outcomes, non-zero margins, matched/conditional estimands, stabilized or machine learning weights, doubly robust and TMLE methods, arbitrary survival endpoints and varying coefficients. Better an honest validated limited package than an expansive unverified package. The project concerns longitudinal causal treatment assignment; it is not a varying-coefficient-model implementation or a complete PhD research framework.

## 11. Instructions for the coding agent

Read this specification and inspect repository/docs. Work incrementally, preserve user changes and historical proposal, ask for meaningful scope or scientific-model changes rather than silently changing estimands. Implement one tested module at a time; first the data contract and direct pairwise kernel, then sequential models and data generation, then diagnostics and Monte Carlo validation, then documentation. Use reproducible R checks and record actual outcomes. Do not change definitions to make a failing reference comparison pass. If a test disagrees with WINS or WeightIt, investigate endpoint coding, weights, normalization and modeling conventions and document the result. Report blockers honestly; never fabricate benchmark data, references, test results or CRAN approval. Do not upload or use private clinical data. Do not submit externally or change remote repository settings without user authorization. Prioritize completed correct P0 functionality over feature sprawl.

## 12. References and evidence

- Wang D, Zheng S, Cui Y, He N, Chen T, Huang B (2025; online 2023). Adjusted win ratio using the inverse probability of treatment weighting. *Journal of Biopharmaceutical Statistics*, 35(1), 21--36. https://doi.org/10.1080/10543406.2023.2275759. Foundation for baseline IPTW-adjusted WR, not claimed as the source of a validated longitudinal variance formula.
- Hernán MA, Robins JM. *Causal Inference: What If*. Chapters 19 and 21 (time-varying treatment and g-methods). https://www.hsph.harvard.edu/miguel-hernan/causal-inference-book/ . Foundation for longitudinal regime identification and IP weighting.
- WINS CRAN manual: https://cran.r-project.org/web/packages/WINS/refman/WINS.html . Inspect `win.stat`, `iptw.weight`, `covipcw` and endpoint coding.
- WeightIt longitudinal vignette: https://ngreifer.github.io/WeightIt/articles/longitudinal-treatments.html ; API: https://ngreifer.github.io/WeightIt/reference/weightitMSM.html .
- cobalt: https://cran.r-project.org/package=cobalt .
- causalWins: https://cran.r-project.org/package=causalWins ; vignette: https://cran.r-project.org/web/packages/causalWins/vignettes/vignette_winRatio.html . Review estimands carefully before comparisons.
- BuyseTest: https://cran.r-project.org/package=BuyseTest ; WinRatio: https://cran.r-project.org/package=WinRatio ; winnify: https://cran.r-project.org/package=winnify .
- CRAN submission checklist: https://cran.r-project.org/web/packages/submission_checklist.html ; policy: https://cran.r-project.org/web/packages/policies.html .
- Course documents: BIOSTAT 615 Final Project Description and Final Project Checkpoint (Nov 20, 2026); professor's proposal feedback shared Nov 22; original IPTWWinDiag SPEC.md (Oct 26, 2026). Course deadlines and grading criteria are authoritative.

**Release claim:** `longWR` estimates a specified marginal treatment-regime win ratio for a constrained two-stage observational design under explicit assumptions, with transparent sequential IP weights, regime-specific diagnostics and reproducible validation. Any claim beyond that must be supported by actual implementation and test results.
