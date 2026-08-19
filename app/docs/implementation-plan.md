# Implementation plan

How Warehouse Advanced gets built: the gating discovery work, the per-feature cost, the
candidate feature catalogue, and the order it should be tackled in.

> ## Read this first
>
> **This plan does not know what Qguar does at this customer.** No licence file,
> configuration export, transaction volumes, or floor observation has been supplied. The
> feature catalogue in §4 is a hypothesis about what a tier-1 WMS typically offers and
> standard Business Central typically lacks.
>
> It is a **starting point for the discovery in §2, not a build order**. Section 3 shows why
> building it as-is would be a serious mistake: the per-feature obligations in
> `feature-ready.md` are heavy enough that the difference between 14 features and 5 is the
> difference between a deliverable project and an undeliverable one.
>
> Phase 0 exists to replace §4 with fact. Nothing in §4 should be started before it does.

## 1. Where the project stands

| | |
|---|---|
| Delivered | `FEAT-CORE-001` — foundation setup, guided setup hub, per-feature wizard, feature facade, permission sets (17 objects, PRs #5–#7) |
| Delivered | `FEAT-HU-001` — handling units: the unit, nesting, contents (PRs #11–#12) |
| Delivered | `FEAT-TASK-001` segment 1 — warehouse tasks: life cycle, priority queue, operator assignment, handling unit move on completion |
| Delivered | `FEAT-INT-001` segment 1 — integration message spine, handler dispatch, two inbound and two outbound message types. **Built on assumed contracts** — see below |
| Delivered | `FEAT-RF-001` segments 1-2 — handheld screen, device register, a swappable scan-through flow, and the short pick. **Not yet seen by an operator** |
| Delivered | `FEAT-TASK-001` segment 2 — partial completion: a job finished with less than it asked for, and why |
| Delivered | `FEAT-WAVE-001` segment 1 — waves: gathering work by a swappable strategy, releasing it as a batch, and closing it |
| Distribution | Per-tenant extension, publisher `matr`, object range `50000..50999` |
| Environment | BC 28.1, runtime 17.0, dev container `mrt28`, production BC online W1 |
| Not started | Everything else in §4 |

**What is delivered was built from §4, not from a capability register.** Both shipped features
carry that caveat in their own technical documentation. Phase 0 can still invalidate them, and
the two chosen so far were chosen precisely because they are the least likely to be invalidated
(§4, "the two that are probably not optional") and because almost everything else depends on them.

Core carries no per-feature knowledge: a feature ships by adding a `WHA Feature` enum value bound
to its own `WHA IFeatureSetup` implementation, and the wizard, the guided setup list, the MCP
registration and the deferred session restart pick it up with no Core change. Adding directed work
changed Core only where the feature genuinely needed foundation support — a second number series on
`WHA Warehouse Setup`.

## 2. Phase 0 — the capability register (gates everything)

Per [gap-analysis.md](gap-analysis.md). **No feature work starts until this is signed off.**

### Inputs to collect

| Input | Source | What it settles |
|---|---|---|
| Qguar module licence list | Licence file / vendor | What is *paid for* — an upper bound, not usage |
| Configuration export | Qguar admin | What is *configured* |
| 12 months of transaction volumes by document type | Qguar database | What is *actually used*, and how hard |
| ~~Current interface specification~~ **Observed interface traffic** | Message logs, database, and the people who operate the interface | The contract the replacement must satisfy. **No written specification exists** — this has to be reconstructed from what actually crosses the boundary |
| Custom report and label inventory | Qguar admin | Output formats that must be reproduced |
| Floor observation and operator interviews | On-site | Undocumented workarounds — the highest-value input |

### Classification

Every capability found lands in exactly one bucket:

- **Standard BC** — the base app already does it, possibly with configuration. Build nothing.
- **Configuration** — BC does it with setup work. Document it, build nothing.
- **Build** — a genuine gap. Becomes a `FEAT-` item.
- **Drop** — Qguar does it, nobody uses it, or the business will change process.

**Watch the drop rate.** A low one means the analysis is not finished, not that the scope is
genuinely large. Record who approved each drop; they get re-litigated otherwise.

### Output

A signed-off capability register: one row per Qguar capability, its bucket, and for **Build**
rows a target feature. That register **replaces** §4 and rewrites
[modules.md](modules.md).

### Sequencing note

Phase 0 is not a blocker on *all* work. `FEAT-INT-001` (§4) can start from the current
interface specification alone, and the cutover model (§6) can be decided in parallel.

## 3. What each feature actually costs

This is the part that determines whether the project is deliverable, and it is easy to
underestimate. `bc-greenfield-template/checklists/feature-ready.md` (in the private `bc-dev-templates`
repo, not reachable from this repo) requires **all** of the following before a feature is done — not just the business logic:

| Obligation | Detail |
|---|---|
| Setup table + page | Single-record, with `Enabled`, delegating to a logic interface |
| Dedicated application area | `Application Area Setup` field + experience-tier subscriber, toggled from `Enabled` |
| Assisted setup step | An `enumextension` value on `WHA Feature` bound to the feature's `WHA IFeatureSetup` implementation |
| Polymorphic logic | Interface + default logic codeunit per entity; no logic in triggers or subscribers; **no custom event publishers** |
| API pages | One per persisted table, in the module's `apiGroup` |
| Demo data | `WHA Demo <Feature>` idempotent `Import()`, covering every field and relation |
| Demo API + MCP config | `[ServiceEnabled] ImportDemoData` in a dedicated `demo<Feature>` group, with agent instructions |
| RapidStart package | Built on demo-data opt-in, feature tables only, never the setup table |
| Permission sets | Every object added as it is created |
| Tests | A `[Test]` **per segment**, added with the segment; unit + integration test plans |
| Documentation | `technical-documentation.md` + getting-started in English **and** the customer language, updated per segment. The customer-language pass is **deferred until a customer is engaged** — English ships with each feature so the translation has a source. |

**Implication:** a "small" feature is not small. Two tables and a page still carry a setup
surface, an application area, a wizard step, demo data, an MCP configuration, a RapidStart
package, tests and two sets of user documentation.

This is the strongest possible argument for a ruthless Phase 0. **Every feature the gap
analysis drops saves far more than its business logic.** Fourteen features at this
obligation level is not a realistic scope; five or six is.

## 4. Candidate feature catalogue — HYPOTHESIS, NOT SCOPE

Marks follow `FEAT-<AREA>-<NNN>`. Sizes are relative shape, not estimates, and assume the
full §3 obligation set:

- **S** — one entity, little cross-module interaction
- **M** — several entities, some standard-BC integration
- **L** — deep integration with standard warehouse documents or posting
- **XL** — new interaction model (UI paradigm, scheduling engine)

| Mark | Feature | Standard BC today | Candidate gap | Size | Depends on |
|---|---|---|---|---|---|
| `FEAT-INT-001` | Integration surface | Standard APIs | API pages and event contracts for the replacement interface and downstream automation | M | Core |
| `FEAT-HU-001` | Handling units | No first-class pallet/container entity; tracking is lot/serial only | License-plate / SSCC-identified unit, nesting, move-as-one, unit history | L | Core |
| `FEAT-TASK-001` | Directed work | Put-away templates, bin ranking, directed put-away and pick | Task queue with priority, operator assignment, interleaving, travel-path sequencing | L | HU |
| `FEAT-RF-001` | Mobile device | No RF/handheld UI; web client is desktop-shaped | Scanner-optimised page set, step-driven flows, offline-tolerant confirm, device registration | XL | TASK |
| `FEAT-WAVE-001` | Wave management | Pick worksheet, release-to-pick; no wave entity | Wave definition, release strategies, templates, workload balancing | L | TASK |
| `FEAT-REPL-001` | Replenishment | Bin replenishment via movement worksheet | Demand-driven and min/max triggers, wave-aware pre-replenishment | M | TASK, WAVE |
| `FEAT-PACK-001` | Packing | Basic shipment posting | Packing station UI, cartonisation, pack verification, packing list output | L | HU |
| `FEAT-LBL-001` | Labelling | Basic report layouts | GS1-128 / SSCC generation, label templates, printer routing per zone | M | HU |
| `FEAT-CNT-001` | Counting | Physical inventory journal, warehouse physical inventory | Perpetual cycle counting by ABC/trigger, tolerance and approval, blind counts | M | TASK |
| `FEAT-QC-001` | Quality hold | Blocked items, bin blocking | Quarantine workflow, inspection disposition, hold/release audit trail | M | HU |
| `FEAT-SLOT-001` | Slotting | Static bin ranking / warehouse classes | Velocity (ABC) analysis, slotting proposals, re-slotting worksheet | M | HU, CNT |
| `FEAT-LAB-001` | Labour management | None | Engineered standards, operator performance, indirect time capture | M | TASK |
| `FEAT-DOCK-001` | Dock and yard | None | Dock door master, appointment booking, trailer and yard position tracking | M | — |
| `FEAT-KPI-001` | Analytics | Standard warehouse reports | Operational KPI queries, throughput and dock-to-stock measures | S | Most of the above |

Object ID blocks are already reserved per module in [modules.md](modules.md).

### The two that are probably not optional

`FEAT-HU-001` and `FEAT-INT-001` are load-bearing regardless of what Phase 0 finds:

- **Handling units** — most WMS execution semantics assume a license-plate entity. Almost
  every other feature references it. If it turns out the customer does not use pallet IDs,
  large parts of this catalogue collapse, which is itself a very valuable Phase 0 finding.
- **Integration** — the project exists to replace an interface. **No written specification of that
  interface exists**, and the customer cannot produce one, so segment 1 was built on assumed
  contracts with the guesses isolated behind an extensible message-type enum: replacing a payload
  shape is one codeunit, and adding a message type touches no existing object. The real contract has
  to be recovered from observed traffic and from the people who run it — which makes it a Phase 0
  input rather than a document to wait for.

### The one with a disproportionate risk

`FEAT-RF-001`. A scanner UI is a different interaction model, not a page set, and it is the
feature most likely to be judged by operators against what Qguar already does. If handheld
work is in scope, prototype it against real operators **early** — before the features it
depends on are finished — because it can invalidate the design of the task queue beneath it.

**Segment 1 is built, and building it early already paid for itself**: it exposed a state the
task queue could reach but never leave — work abandoned mid-job stayed *In progress* with nobody
holding it, invisible to everyone. Fixed, with tests. That is the cheap version of what this
feature is for. **The expensive version is still outstanding: no operator has seen the screen.**
Until one has, treat the step sequence as unvalidated — which is why it sits behind a single
swappable interface rather than in the page.

## 5. Suggested sequence

Assuming Phase 0 confirms a broad scope. **Re-derive this from the real register.**

```
Phase 0   Capability register                        ← gates everything below
          └─ FEAT-INT-001 may start in parallel

Wave A    FEAT-HU-001      handling units            ← delivered
          FEAT-INT-001     integration surface       ← segment 1 delivered on assumed contracts

Wave B    FEAT-TASK-001    directed work             ← segment 1 delivered
          FEAT-RF-001      mobile device             ← segment 1 delivered; needs operator review

Wave C    FEAT-WAVE-001    wave management           ← segment 1 delivered
          FEAT-PACK-001    packing
          FEAT-LBL-001     labelling

Wave D    FEAT-REPL-001    replenishment
          FEAT-CNT-001     counting
          FEAT-QC-001      quality hold

Wave E    FEAT-SLOT-001    slotting
          FEAT-LAB-001     labour management
          FEAT-DOCK-001    dock and yard

Wave F    FEAT-KPI-001     analytics
```

`FEAT-DOCK-001` has no dependencies and can move anywhere it fits.

Each feature runs the greenfield loop — intake → design → document → implement → test →
deliver — **in segments**, with a test and a documentation update shipping alongside each
segment rather than batched at the end.

## 6. Cutover interaction

Undecided, and it changes the plan materially:

- **Big bang** — everything in the register must ship before cutover. Sequencing is dictated
  by the cutover date, and the drop rate in Phase 0 becomes the main lever.
- **Parallel run** — features ship incrementally while Qguar still runs. `FEAT-INT-001` then
  has to handle two systems holding stock at once, which is a substantially harder integration
  problem and should be sized accordingly.

The `Enabled` flag and per-feature application areas already support a phased rollout: a
feature can ship dark and be switched on per company when the business is ready.

## 7. Risks

| Risk | Why it matters | Mitigation |
|---|---|---|
| Scope taken from this document instead of Phase 0 | The catalogue is a hypothesis; §3 shows the cost of over-scoping | Treat §4 as an interview agenda; rewrite from the signed register |
| Handling units turn out not to be used | Invalidates the dependency spine of the catalogue | Establish it in the first Phase 0 session |
| Handheld expectations set by Qguar | `FEAT-RF-001` is judged against an incumbent operators know | Prototype early with real operators |
| Undocumented Qguar customisations | The classic source of late scope | Floor observation and interviews, not just the config export |
| Dev container is US, production is W1 | Localisation-specific behaviour will not surface locally | Rebuild the container from a W1 artifact before posting-related work |
| Public repo needs private conventions | A fresh clone will not build; CI cannot run without access | Accepted trade; revisit if CI is introduced |
| No LICENSE, dead manifest URLs | `dmom.ai/privacy`, `/eula`, `/help` do not exist | Publish the pages, or point the manifest somewhere real, before customer delivery |

## 8. Immediate next steps

1. **Run the test suite once.** 108 automated tests exist across five codeunits and **not one has
   ever been executed** — they are compile-verified only, because publishing to the dev container
   needs credentials that are not in the repo. Until they have run green once, every claim this
   project makes about its own behaviour rests on the compiler agreeing the code parses.
2. **Run Phase 0.** Collect the six inputs in §2 and produce the capability register. This is
   consulting work, not development work, and it is the highest-value thing available. It is now
   badly overdue: **five features** have been built from the hypothesis, and each further one raises
   the cost of a register that contradicts it.
3. **Run the operator review** for `FEAT-RF-001`, per
   [FEAT-RF-001-MobileDevice/operator-review.md](FEAT-RF-001-MobileDevice/operator-review.md). The
   handheld has never been seen by anyone who would use it.
4. **Decide the cutover model** (§6) — it changes sequencing and the difficulty of
   `FEAT-INT-001`.
5. ~~**Get the current interface specification.**~~ **There is none.** Confirmed with the customer:
   no written contract exists for the interface being replaced, and none can be produced. This was
   accepted as a standing condition, and `FEAT-INT-001` was built on assumed contracts rather than
   waiting. What remains is to establish the five inputs listed at the end of
   [FEAT-INT-001-Integration/technical-documentation.md](FEAT-INT-001-Integration/technical-documentation.md)
   — the real message set, payload shapes, transport, volumes, and the cutover model — by observing
   the live traffic and interviewing the people who run it, since no document will supply them.
6. **Rewrite [modules.md](modules.md) and §4 of this document** from the signed register.

Until step 1 produces something, further AL beyond the delivered Core module is building
against a guess.
