# Gap analysis: turning candidate scope into real scope

The module map in [modules.md](modules.md) is a hypothesis. This document is the method for
replacing it with fact. Nothing in `app/src/` should be built for a module until its row
here is filled in.

## Why this step is not optional

Two failure modes dominate WMS replacement projects, and both are cheap to avoid at this
stage and expensive to fix later:

1. **Rebuilding features nobody uses.** A WMS ships with far more capability than any one
   customer switches on. Building to the product's feature list rather than the
   customer's usage produces an app several times larger than needed.
2. **Missing the undocumented ones.** The features that hurt are the local
   customisations, scripts, and label formats that were never written down and are known
   only to the people on the floor.

## Inputs to collect

| Input | Source | What it settles |
|---|---|---|
| Qguar module licence list | Customer's licence file / vendor | Which modules are *paid for* — an upper bound, not usage |
| Configuration export | Qguar admin | Which are *configured* — closer to reality |
| 12 months of transaction volumes by document type | Qguar database | Which are *actually used*, and how hard |
| Interface specification (current) | Existing integration | The contract the replacement must satisfy |
| Custom report and label inventory | Qguar admin | Output formats that must be reproduced |
| Floor observation / operator interviews | On-site | Undocumented workarounds — the highest-value input |

## Classification

Each capability found lands in exactly one bucket:

- **Standard BC** — covered by the base app, possibly with configuration. Build nothing.
- **Configuration** — covered by BC with setup work. Document it, build nothing.
- **Build** — genuine gap. Goes into a module in `modules.md` with an ID block.
- **Drop** — Qguar does it, nobody uses it, or the business is willing to change process.
  Record the decision and who made it; these get re-litigated later otherwise.

The **Drop** column is the one that determines whether this project is deliverable. Treat
a low drop rate as a sign the analysis is not finished.

## Output

A signed-off capability register: one row per Qguar capability, its bucket, and for
**Build** rows a target module. That register supersedes the candidate table in
`modules.md`, which should then be rewritten to match it.

## Open questions

- [ ] Which BC localisation is the production tenant? The dev container is **US**, which
      will not surface localisation-specific behaviour if production is European.
- [ ] Is the app a per-tenant extension (PTE) or destined for AppSource? This decides
      whether the `50000..50999` range and `WHA` affix stand as-is.
- [ ] What is the cutover model — big bang, or does the new app run alongside Qguar?
- [ ] Which automation is planned "on top of" the WMS solution, and does it consume the
      `Integration` module's API surface or drive the UI?
