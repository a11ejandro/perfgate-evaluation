# Perfgate evaluation package

This directory is the canonical study package for evaluating Perfgate against
the `perfgate-micropost` subject. It is deliberately separate from both the gem
and the subject application. Nothing here changes Perfgate's implementation or
turns advisory evidence into a validated merge gate.

The package supports three distinct activities:

1. **Calibration** measures null behavior, explores the fixed regression
   corpus, estimates resource requirements, and freezes the confirmatory
   design. Calibration results may change the later plan.
2. **Held-out validation** evaluates predeclared criteria without tuning.
3. **Statistical simulation** measures interval coverage and decision behavior
   when the data-generating effect is known. Application injections cannot, by
   themselves, establish interval coverage because their true effect is not
   known.

The current study is limited to the implemented
`historical_stored_baseline` reference design and independent-sample estimator.
It does not represent same-worker randomized AB/BA blocks, interleaving, or a
paired estimator.

## Directory map

```text
evaluation/
  PROTOCOL.md                 Study design and analysis commitments
  config/
    study.yml                 Stage, replication, environment, and outcomes
    conditions.yml            A/A control and fixed injected regressions
    simulations.yml           Known-effect simulation scenarios
  bin/
    freeze_plan               Resolve refs and freeze an auditable JSON plan
    run_trial                 Capture one reference or candidate arm
    run_hosted_batch          Dispatch, download, and validate a hosted batch
    validate_bundle           Validate schemas, checksums, and execution state
    collect_results           Produce trial- and metric-level CSV datasets
    analyze_results           Produce descriptive estimates and audit report
    simulate_decisions        Exercise the implemented rule under known effects
    study_status              Show progress and the next frozen-plan action
  schemas/                    Schemas for study-owned plans and trial manifests
  templates/                  Operational-observation form for a later team study
```

Generated results are ignored by Git and must be archived separately under an
immutable identifier. Frozen plans and their checksum sidecars should be
committed before execution.

## Sequence

### 1. Freeze and run calibration

Review `config/study.yml`, especially the environment class and replication
counts. Then create a plan while the subject repository is clean:

```bash
mkdir -p plans
bin/freeze_plan --stage calibration --output plans/micropost-calibration-v1.json
```

The command records exact application and Perfgate revisions, configuration and
workload digests, the dataset contract, condition order, and the analysis
contract. It also writes a `.sha256` file. Any later edit produces a different
plan identity.

For each entry in `trials`, check out its exact `reference_revision` and run:

```bash
bin/run_trial \
  --plan plans/micropost-calibration-v1.json \
  --trial TRIAL_ID \
  --arm reference \
  --repository ../perfgate-micropost
```

Set `PERFGATE_ENVIRONMENT_CLASS` to the exact class recorded in the plan for
every non-pilot capture. Set `PERFGATE_WORKER_INSTANCE` to an opaque identifier
for the provisioned worker; it need not reveal a hostname.

Then check out the exact `candidate_revision` and pass the reference arm's run
directory:

```bash
bin/run_trial \
  --plan plans/micropost-calibration-v1.json \
  --trial TRIAL_ID \
  --arm candidate \
  --repository ../perfgate-micropost \
  --reference results/STUDY/calibration/TRIAL_ID/reference/runs/RUN_ID
```

`run_trial` refuses dirty repositories and revision mismatches. It preserves
execution errors as errors, validates Perfgate schema-v2 artifacts and
checksums, and records environment and timing metadata in `trial.json`.

For hosted execution, `.github/workflows/evaluation.yml` checks out the exact
arm revision from the frozen plan. The reference and candidate arms remain
separate workflow runs because the current implementation consumes a stored
baseline. Dispatch trials in the plan's `schedule_index` order and distribute
them over the preregistered days and workers.

Run a bounded schedule segment with limited concurrency:

```bash
bin/run_hosted_batch \
  --plan plans/perfgate-micropost-calibration-v1.json \
  --from 1 \
  --count 42 \
  --concurrency 3
```

The batch command records GitHub run IDs, downloads both arms, validates the
schema-v2 bundles and checksums, and resumes from locally downloaded completed
arms. A failed arm is not treated as a completed comparison.

### 2. Collect and analyze calibration

```bash
bin/collect_results \
  --plan plans/micropost-calibration-v1.json \
  --results results \
  --output derived/calibration

bin/analyze_results \
  --plan plans/micropost-calibration-v1.json \
  --input derived/calibration \
  --output derived/calibration-report
```

The report keeps all five evidence states separate and reports missing or
failed captures separately. Evidence FAIL is not replaced by the advisory
policy result.

### 3. Run known-effect simulations

```bash
bin/simulate_decisions \
  --stage calibration \
  --output simulation-results/calibration
```

This invokes the exact Perfgate revision pinned by the subject application. Raw
replicates are retained. Simulation is evidence about the implemented
statistical procedure under the declared generators, not evidence about host
drift, workload representativeness, or production benefit.

### 4. Freeze held-out validation

After calibration, specify confirmatory replication counts and acceptance
criteria in a new configuration snapshot. Record the immutable calibration
artifact digest, set `held_out.ready: true`, and freeze a held-out plan:

```bash
bin/freeze_plan \
  --stage held_out \
  --config config/study-held-out.yml \
  --output plans/micropost-held-out-v1.json
```

The tool refuses to create a held-out plan while those fields are unresolved.
Do not inspect held-out outcomes while changing thresholds, workloads,
injections, exclusions, or analysis rules.

The active version 1.1 design is documented in `HELD_OUT_VALIDATION.md`. Its
configuration files are `config/study-held-out-v1.1.yml` and
`config/simulations-held-out.yml`. Freeze it with:

```bash
bin/freeze_plan \
  --stage held_out \
  --config config/study-held-out-v1.1.yml \
  --output plans/perfgate-micropost-held-out-v1.1.json
```

### 5. Audit readiness before publishing or executing

```bash
bin/check_readiness \
  --plan plans/perfgate-micropost-held-out-v1.1.json \
  --archive PATH/TO/perfgate-micropost-calibration-v1.tar.gz \
  --output readiness/perfgate-micropost-held-out-v1.1.json
```

A local `ready` result is necessary but not authorization to collect held-out
data. First publish the immutable calibration release and push the frozen plan
and checksum. The audit deliberately reports `execution_authorized: false` so
preparation cannot silently start the confirmatory study.

After collection and held-out simulation, evaluate the predeclared criteria:

```bash
bin/assess_acceptance \
  --plan plans/perfgate-micropost-held-out-v1.json \
  --application-summary derived/held-out-report/summary.json \
  --simulation-summary simulation-results/held-out/summary.json \
  --output derived/held-out-acceptance
```

Every criterion is reported. Failure does not trigger tuning or replacement of
held-out observations; a changed design starts a new study version.

## What this first study can and cannot establish

Repeated A/A comparisons can estimate false-FAIL, WARN, incomplete-evidence,
and rerun-reversal behavior for this workload set and environment class. Fixed
regression branches can estimate sensitivity to those particular injected
changes. Known-effect simulation can estimate coverage and power curves under
its declared distributions.

The study cannot establish causal effects from historical-baseline comparisons,
power at arbitrary application-level effect sizes from fixed injections,
cross-application generality, or operational benefit to engineering teams.
Reference-design comparisons also remain future work because Perfgate currently
implements only the historical stored-baseline design.

## License

The evaluation software is licensed under Apache License 2.0; see `LICENSE`.
The authored study data and documentation are licensed under Creative Commons
Attribution 4.0 International (CC BY 4.0); see `LICENSE-DATA`. Bundled source
snapshots and third-party material retain their own licenses.
