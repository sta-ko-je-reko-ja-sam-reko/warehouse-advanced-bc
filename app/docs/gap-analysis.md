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

## Decisions taken

- **Distribution: per-tenant extension (PTE).** Not AppSource. The `50000..50999` range
  and the `WHA` affix therefore stand as-is — no ID range or affix registration with
  Microsoft is required. The affix is kept anyway: it prevents collision with other
  extensions installed in the same tenant, which is a real risk in a customer environment,
  not just an AppSource formality.
- **Production localisation: W1.** No country localisation.

## Open questions

- [ ] What is the cutover model — big bang, or does the new app run alongside Qguar?
- [ ] Which automation is planned "on top of" the WMS solution, and does it consume the
      `Integration` module's API surface or drive the UI?

## Known environment mismatch

The dev container is built from a **US** sandbox artifact, but production is **W1**. For
warehouse objects the overlap is high and the risk is low, so this is not urgent — but it
is not zero either, and the honest fix is to rebuild the container from a W1 artifact
before serious work on modules that touch posting or documents.
