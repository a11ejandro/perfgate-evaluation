# Pre-execution amendment: held-out v1.1

Date: 2026-09-20  
Status: frozen locally; no held-out observations collected

This amendment supersedes `perfgate-micropost-held-out-v1` before execution.
The original v1 plan and checksum remain preserved in the repository.

## Reason

The first calibration archive was prepared locally but never attached to or
published from the draft GitHub release. Prepublication review found an
author-local absolute path in one derived CSV and found that archive-level
licensing was incomplete. The archive was repackaged before public deposit:

- the `comparison_path` column now uses archive-relative paths;
- Apache-2.0 and CC BY 4.0 terms and packaging provenance were added;
- measurements, evidence documents, statistical outputs, and decisions were
  not changed.

The corrected archive has SHA-256
`9fe7b797ba95075a740e71691b7e0dcd26b0f4bfcef867cd11fa468f4101c1f4`.

## Ref pinning

The v1 configuration named `main` for the reference and A/A candidate. Those
symbolic refs resolved to `538221f853c5f0b2ae36be14bcaf576947b457f9` when v1
was frozen, but later documentation and licensing commits moved `main`. Version
1.1 records the same resolved commit directly so a refreeze cannot drift.

## Unchanged design

Automated comparison of v1 and v1.1 confirms that the following are identical:

- all 240 trials, their randomized order, revisions, and reversal pairs;
- the analysis specification, estimator, MEIs, and acceptance criteria;
- the simulation specification and randomization seed;
- the protocol, evaluation machinery, Perfgate revision, workload digests,
  dataset contract, and resolved subject reference revision.

No held-out run existed when this amendment was made. Version 1.1 must be
published with its checksum and the corrected calibration archive before any
held-out execution.
