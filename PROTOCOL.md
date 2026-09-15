# Preregisterable evaluation protocol

Status: **calibration protocol; no confirmatory results reported**

## Objective

Evaluate the operating behavior of the Perfgate revision pinned by
`perfgate-micropost` for its declared Rails/RSpec workloads. The study evaluates
the tool and decision procedure as implemented. It does not assume that a
comparison result is correct, causal, or suitable for merge blocking.

## Research questions

1. Under A/A conditions, how often does the suite produce PASS, WARN, FAIL,
   INCONCLUSIVE, or INCOMPARABLE evidence?
2. How often do repeated comparisons with unchanged code reverse outcome?
3. Which fixed injected regressions produce FAIL evidence, on which metrics,
   and with what observed effect and uncertainty?
4. Under declared known-effect generators, what coverage does the implemented
   interval attain and how does the five-state decision distribution change
   around the configured MEIs?
5. How do evidence outcomes and observed effects vary across captured worker
   instances and days, and what runner time does the workflow consume?

Operational usefulness, investigation effort, and cross-application
generalizability require later studies. A form is included for those data, but
they are not outcomes of the automated initial evaluation.

## Design boundary

The experimental unit for the application study is one complete Perfgate
comparison: an independently measured reference run followed by an independently
measured candidate run. Condition order is randomized by the frozen plan. Arm
order is not randomized: reference precedes candidate because the implementation
uses a stored historical baseline. Trials are neither paired measurements nor
randomized AB/BA blocks.

The A/A condition resolves both arms to the same application commit. Injection
conditions resolve the reference to the frozen main commit and the candidate to
one frozen regression commit. Equality of recorded fingerprints is a declared
comparability check; it does not control unobserved temporal, host, thermal, or
neighbor-load variation.

## Study stages

### Pilot

Pilot runs test mechanics and injection viability. They may be rerun or used to
change the protocol. They are excluded from calibration and held-out estimates.

### Calibration

The initial configuration schedules 30 A/A comparisons and 12 comparisons for
each of eight fixed injections. These counts are design starting points, not a
claim of adequate precision. Calibration estimates determine whether more runs,
different effect injections, or a different environment are required.

Calibration may inform a separate held-out plan. Every change to workloads,
data, MEIs, reference design, estimator, multiplicity rule, exclusions, or
environment creates a new configuration and study identifier.

### Held-out validation

Held-out replication counts and acceptance bounds are deliberately unresolved
in the calibration configuration. They must be selected from operational risk
and calibration precision, recorded with the calibration artifact digest, and
frozen before held-out outcomes are observed. The machinery rejects an
unresolved held-out plan.

## Outcomes

The primary observable outcome is Perfgate's **evidence result**, not the
organizational policy result. PASS, WARN, FAIL, INCONCLUSIVE, and INCOMPARABLE
are counted separately. Execution failure, missing artifact, invalid schema, or
checksum failure is an execution/collection outcome and is never recoded PASS.

Primary estimates are:

- suite-level A/A false-FAIL proportion;
- suite-level A/A WARN proportion;
- the complete A/A five-state distribution;
- condition-specific FAIL proportion for each fixed injection;
- condition- and metric-specific evidence distributions;
- rerun reversal proportion for preassigned consecutive replicate pairs;
- elapsed runner time per arm and complete comparison.

Secondary descriptive outputs include median changes, bootstrap bounds, sample
counts, MEIs, exact decision rules, and outcome distributions by worker identity
and calendar day. Cross-worker results are descriptive unless the frozen
held-out plan declares a model and adequate worker replication.

The term “power” is reserved for a data-generating alternative with a declared
true effect. Fixed application branches have unknown true performance effects;
their FAIL proportions are detection rates for those changes, not formal power.
Known-effect simulations report decision probability at the warning MEI,
failure MEI, and larger alternatives. High FAIL probability is not expected at
the exact boundary merely because the boundary is called an MEI.

## Statistical analysis

For observed binomial proportions, the analysis reports counts, denominators,
and two-sided 95% Wilson intervals. These intervals describe precision of the
study-level rate estimates; they are unrelated to Perfgate's per-comparison
bootstrap interval.

Rerun reversal is defined before observation: repetitions `(1,2)`, `(3,4)`, and
so on form disjoint pairs within condition and phase. A pair reverses when both
trials are valid and their evidence results differ. Invalid or missing members
are reported and excluded from the reversal denominator, not imputed.

No optional stopping is permitted within a frozen stage. Calibration can lead
to a newly frozen held-out plan, but calibration results are not pooled with
held-out results for confirmatory claims.

Simulation uses the exact pinned Perfgate interval and decision code, fixed
pseudorandom seeds, declared distributions, and retained replicate-level data.
Coverage is the proportion of intervals containing the known population median
difference. The initial scenarios estimate per-metric coverage at the
Bonferroni-adjusted level; they do not estimate joint family-wise coverage under
a realistic cross-metric dependence structure. This supports only the simulated
generators and settings.

## Randomization and scheduling

The plan generator stratifies by condition, creates immutable repetition IDs,
and randomizes the order of condition comparisons with a recorded seed. It does
not randomize arm order. Runs should be distributed across at least three days
and three independently provisioned worker instances. Scheduling constraints
are checked in the audit report; failing them weakens or prevents the intended
environmental analysis.

## Exclusions and missing data

Automated exclusion is limited to:

- plan or revision mismatch;
- dirty source for non-pilot stages;
- invalid or missing schema/checksum evidence;
- workload execution failure;
- absent reference artifact;
- duplicate trial-arm capture.

All such events remain in the collection audit. Performance outliers are not
deleted. A rerun creates a new preregistered trial identifier; it does not
replace an unfavorable observation. Any manual exclusion requires a reason,
author, timestamp, and sensitivity analysis with and without the observation.

## Acceptance and promotion

Calibration has no pass/fail acceptance threshold. Its purpose is to estimate
variance, null behavior, sensitivity to the fixed corpus, duration, and the
sample size needed for held-out evaluation.

Before held-out validation, the author and workload owners must specify bounds
for false FAIL, WARN, incomplete evidence, reversal, interval coverage under
selected generators, detection at selected alternatives, worker instability,
and compute time. A blocking recommendation is permitted only if the complete
held-out artifact satisfies every predeclared criterion and exactly matches the
workload set, reference design, estimator, MEIs, multiplicity rule, environment
class, Perfgate revision, and policy version. Even then, the result supports
only that calibrated scope.

Until that occurs, advisory results may motivate investigation but must not
automatically block merges.

## Threats to validity

- Fixed injected branches may be unrealistically large and do not provide a
  controlled effect-size curve.
- The Micropost application is one synthetic Rails subject.
- Historical references confound revision with time and possibly host.
- Eight observations per run may provide limited precision after family-wise
  adjustment.
- Hosted runner labels do not guarantee identical hardware or load.
- Simulation distributions may not resemble application observations.
- Instrumentation and deterministic fixture resets may alter the behavior being
  measured.
- Operational and diagnostic value cannot be inferred from automated outcomes.
