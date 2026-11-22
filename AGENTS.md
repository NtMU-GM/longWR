# longWR Project Instructions

- Read SPEC.md before implementing any feature.
- Implement one milestone at a time.
- Prioritize statistical correctness over optimization.
- Write unit tests for every core statistical function.
- Run tests after completing each implementation step.
- Verify results against WINS and WeightIt where applicable.
- Never fabricate results or silently change the estimand.
- Maintain AI_USAGE.md throughout development.
- Do not modify the project scope without approval.
- Do not push to GitHub or submit to CRAN without approval.

## AI Usage and Reproducibility

- Maintain AI_USAGE.md throughout development.
- Record representative prompts, models, implementation decisions,
  errors, fixes, verification results, and actual human review.
- Maintain AGENTIC_TUTORIAL.md as a reproducible guide to building
  longWR using agentic coding.
- Update both documents after each development phase.
- Do not include private conversations or unnecessary chat transcripts.
- Never fabricate AI usage records, human contributions or test results.

## Computational Efficiency

- Write efficient, readable, and memory-conscious R code.
- Analyze time and space complexity for core algorithms.
- Avoid unnecessary loops, repeated computations, and memory allocations.
- Avoid constructing full pairwise matrices for large datasets.
- Use vectorization when it improves performance without
  compromising numerical stability.
- Profile and benchmark computational bottlenecks before optimization.
- Verify optimized algorithms against the direct reference implementation.
- Document computational complexity and measured performance.
- Prioritize statistical correctness over premature optimization.

## Code Documentation and Comments

- Use clear, professional English comments.
- Document all exported functions using roxygen2, including
  parameters, return values, examples, and statistical assumptions.
- Explain nontrivial statistical formulas, algorithmic decisions,
  numerical stability, and edge-case handling.
- Document internal helper functions where appropriate.
- Explain why a code block is necessary, not merely what it does.
- Avoid redundant comments that restate obvious code.
- Keep documentation consistent with SPEC.md.