# Held-out validation preregistration

Status: **prepared locally; do not execute until the frozen plan is published**

This document defines five preparation steps for the first held-out evaluation
of Perfgate on `perfgate-micropost`. It is confirmatory only for the frozen
application, workload set, decision procedure, environment class, and
historical stored-baseline design. It is not a validation of direct merge
blocking, causal attribution, other applications, or other environments.

## Step 1 — Lock the claim and analysis boundary

The primary application claim is limited to the distribution of Perfgate's
five evidence states under new A/A observations and new observations of the
eight already defined fixed regression branches. The evidence result, not the
advisory policy result, is the primary outcome. Fixed source changes have
unknown true effects; their FAIL proportions are condition-specific detection
rates, not power at an MEI.

Known-effect simulation separately evaluates the interval and decision code
under three declared lognormal generators. It does not validate host behavior,
application representativeness, or causality.

## Step 2 — Lock acceptance criteria before outcomes

All bounds use the two-sided 95% Wilson interval already specified by the
protocol. A bound is assessed against the interval endpoint, not only the point
estimate.

| Criterion | Predeclared requirement | Interpretation |
|---|---:|---|
| Collection completeness | at least 98% | execution quality |
| A/A false FAIL | upper bound at most 5% | false blocking evidence |
| A/A metric WARN | upper bound at most 1% | metric-derived false warning evidence |
| A/A incomplete evidence | upper bound at most 15% | INCONCLUSIVE plus INCOMPARABLE |
| Rerun reversal | upper bound at most 10% | workflow-level repeatability |
| Each fixed-injection FAIL rate | lower bound at least 80% | sensitivity to each frozen change |
| Median captured comparison time | at most 60 seconds | excludes queue and job setup |
| Simulation interval coverage | lower bound at least 99% in every group | model-specific interval behavior |
| Simulation null FAIL | upper bound at most 1% in every null group | model-specific false FAIL |
| Simulation WARN-or-FAIL at declared actionable effects | lower bound at least 90% | model-specific actionable detection |

Overall A/A WARN is reported but is not an acceptance criterion because the
implemented evidence result combines metric warnings with informational
compatibility reservations. Calibration produced 28/30 overall WARN but zero
metric WARN across 600 A/A metric decisions. Treating those as the same
quantity would make the criterion uninterpretable.

The design cannot decompose a worker effect because GitHub-hosted workers are
ephemeral and each arm uses a distinct worker identity. It estimates behavior
of the complete hosted workflow across workers, but **cross-worker stability is
not established**. This exclusion alone prevents a direct-blocking validation
claim under the paper's stronger requirements.

## Step 3 — Fix sample sizes and schedule

The held-out application plan uses 80 A/A comparisons and 20 comparisons for
each of eight fixed injections: 240 comparisons and 480 independently captured
arms. With zero A/A FAIL outcomes, 80 trials give a 95% Wilson upper bound of
approximately 4.6%. With 20/20 FAIL outcomes, a condition's 95% Wilson lower
bound is approximately 83.9%. Counts are even so all trials belong to
preassigned consecutive reversal pairs.

Execution must span at least five UTC dates and at least 50 distinct hosted
worker identities. These minima prevent a one-day or one-worker result from
satisfying the plan; they do not identify a worker variance component.

Held-out simulation uses 2,000 replicates for each scenario/effect group, the
same sample size of eight observations per arm, and family size 15. Seeds and
all generators are fixed in `config/simulations-held-out.yml`.

## Step 4 — Freeze materials and provenance

The held-out configuration pins the completed calibration record and its
digest, Perfgate through the subject lockfile, the subject reference and eight
condition refs, workload-source digests, dataset and Perfgate configuration,
analysis settings, simulation configuration, and randomized trial schedule.
Changing any pinned input requires a new study identifier and plan.

Before execution, publish the frozen plan and checksum in the evaluation
repository and publish the prepared calibration archive. Do not replace a
frozen plan. Amendments require a new version plus a dated reason, made before
the affected outcomes are observed.

## Step 5 — Pass the readiness audit, then preserve the blind boundary

The readiness audit must verify the plan checksum and schema, exact revisions,
artifact digests, resolved acceptance criteria, even replication counts,
trial-count arithmetic, and absence of pre-existing held-out results. Once the
plan is published, execute in schedule order without inspecting aggregate
outcomes or changing workloads, thresholds, exclusions, generators, or sample
sizes. Collection failures remain failures; replacement trials require a new
predeclared identifier and cannot overwrite observations.

After collection, run the frozen analysis and acceptance program once. Report
every criterion, including failures. Do not pool calibration and held-out data
for confirmatory estimates.
