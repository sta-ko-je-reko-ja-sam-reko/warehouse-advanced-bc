# Implementation plan

How Warehouse Advanced gets built: the gating discovery work, the per-feature cost, the
candidate feature catalogue, and the order it should be tackled in.

> ## Read this first
>
> **This plan does not know what the incumbent WMS does at this customer.** No licence file,
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
| Delivered | `FEAT-LBL-001` segment 1 — label codes: GS1 SSCC with its check digit, or a sequential licence plate. Closes the gap `FEAT-HU-001` left open |
| Delivered | `FEAT-PACK-001` segment 1 — the packing bench: open a carton, fill it, check it, close it. The carton is a handling unit |
| Delivered | `FEAT-REPL-001` segment 1 — replenishment rules: min/max per pick bin, two ways of measuring the bin, and a run that raises the work to top it up |
| Delivered | `FEAT-CNT-001` segment 1 — count sheets: blind counting, a tolerance, and an approval before a difference is accepted |
| Delivered | `FEAT-QC-001` segment 1 — quality hold: stopping a handling unit and everything on it, three dispositions, and an audit trail that cannot be deleted |
| Delivered | `FEAT-LAB-001` segment 1 — labour management: standards, finished work turned into measured time, and the hours nobody spent on a job. The first feature that only *reads* what the app already recorded |
| Delivered | `FEAT-SLOT-001` segment 1 — slotting: ABC velocity from the app's own pick history, and proposals for items sitting in a worse bin than their class deserves |
| Delivered | `FEAT-DOCK-001` segment 1 — dock and yard: doors, yard positions, and a vehicle visit booked, checked in, brought to a door and sent away. The only feature that depends on nothing else in the app |
| Delivered | `FEAT-KPI-001` segment 1 — analytics: five measures over what the app already recorded, kept as snapshots so one period can be compared with another. **No dock-to-stock** — nothing links a put-away to the vehicle that brought the goods |
| Delivered | **A correctness fix and two stale claims.** Replenishment measured mixed units of measure as one number and hid stock held in another; both are fixed and converted through the item's base unit. Two *Not done* lists had gone out of date — analytics said the app ships no role centre, handling units said it holds no contents |
| Delivered | `FEAT-CORE-001` — **documentation, back-filled.** The foundation shipped in PRs #5–#7 with none, and was the only feature without a docs folder. Four tests added for the enum mechanism that everything else in the app depends on |
| Delivered | `FEAT-CORE-001` — **the role centre**: a home page owned by the foundation whose tiles are contributed by the features themselves, through an extensible enum. Core names no feature. Nine features contribute; five deliberately do not |
| Delivered | `FEAT-INT-001` segment 2 — retention: the message log offered to Business Central's own retention policy framework, rather than a bespoke clean-up this feature would have imitated badly |
| Delivered | Scheduling for `FEAT-SLOT-001`, `FEAT-LAB-001` and `FEAT-KPI-001` — the last piece of catalogue work that needed nothing from Phase 0. Every recurring run in the app can now be given to the job queue |
| Delivered | `FEAT-REPL-001` segment 2 — looking ahead: a bin weighed against what is already promised out of it, pre-replenishment for one wave, and a codeunit a job queue can call |
| Delivered | `FEAT-WAVE-001` segment 2 — templates and workload: a reusable wave definition, a scheduled run for the job queue to call, and a cap measured in **minutes of work** rather than a count of jobs. The first time one feature's engineered standards are used to *plan* rather than to measure |
| Delivered | `FEAT-TASK-001` segment 3 — the source document: work raised from a standard warehouse receipt or shipment, and a job that knows which order it is serving. The first `pageextension` in the app |
| Delivered | `FEAT-CNT-001` and `FEAT-QC-001` segment 2 — **posting**: a shared engine, chosen per feature, that turns a counted difference into an adjustment and a scrapped pallet into a write-off. Built once, in a module that is deliberately **not a feature** — see [inventory-posting.md](inventory-posting.md). **No ledger entry has ever been written by it** |
| Delivered | `FEAT-TASK-001` segment 4 — **the loop closed.** Finishing a job fills in `Qty. to Receive` or `Qty. to Ship` on the document it came from, so the quantity Business Central posts is the one the floor decided. Behind a setting that ships **off**, because turning it on is a decision about who owns the document. `WHA ITaskSource` gained `WriteBack`, so what writing back means stays with the source that knows the document; it adds rather than sets, because a follow-up after a short pick serves the same line and must not erase what the first job did |
| Delivered | `FEAT-TASK-001` segment 5 — **item tracking on a job.** A directed pick of a tracked item could not say what it picked; the fields now exist and fill themselves in where the answer is knowable — from a pallet holding exactly one lot of the item, or from a partner system that asked for one. A mixed pallet fills in nothing, because that is the case where guessing is wrong. **The operator still cannot scan a lot**: adding a step to the handheld flow is an operator-review question, and the review has still not happened |
| Delivered | `FEAT-RF-001` segment 3 — **the handheld is a handheld.** A control add-in draws the page as a scanner rather than as a Business Central card, and a **Simulator** action puts a device frame around it and offers the labels within reach as buttons, so the operator review can be run from a desk against the *real* flow. The add-in decides nothing: it is sent one state document, built in AL and covered by tests, because nothing in this project can run JavaScript and behaviour in the script would be a second implementation nobody could check. **No browser has executed a line of it** |
| Delivered | **Two scheduled runs made honest about time.** Analytics captured only the period ending today, so a job queue entry that failed for a week lost that week permanently — the history broke exactly where the schedule did. It now fills in the days it missed, bounded by a setting, and states the one thing a backfill cannot fix: a day worked out later is worked out from the records as they stand now. Labour read every job the warehouse had ever finished, on every run, for ever; it now reads a window, and the dates go on the record before it is read rather than being checked after |
| Delivered | `FEAT-CNT-001` segment 3 — **counting a tracked item can be posted.** Bin content aggregates across lots, so a sheet filled by bin carried no lot and the item journal would refuse the adjustment; the feature's own documentation had said so since segment 2 and named the fix. *Bins by lot* is that fix — a third selection reading warehouse entries rather than bin content. Carried along: the integration job-queue entry point now stops when the feature is switched off, which every other scheduled run in the app already did |
| Delivered | **A browser bench for the handheld** — `tools/rf-simulator/`. The operator review has been the highest-value work on `FEAT-RF-001` since it shipped and has never run, blocked on a company, sample data and a container credential rather than on anybody's time. One self-contained HTML file ports the step sequence, the wording and every refusal from `WHA RF Standard Flow`, so the *sequence-and-wording* half of the review can happen at a desk today. It settles nothing about a scanner in one hand and a pallet in the other, and says so in three places |
| Delivered | `FEAT-INT-001` segment 3 — **the message set widened from four types to twelve**, from evidence by analogy: a production connector integrating BC with an external warehouse system, read for what a BC-side warehouse interface actually carries. The direction flips, because there BC is the host and here the app *is* the warehouse. Three of the four new inbound types read **no payload at all** — they name their subject in the external ID, so there is no schema in them to guess wrong. Master-data synchronisation, a fifth of that connector, is **not applicable here**: both ends are the same database |
| Delivered | **The capability register, in draft.** [gap-analysis.md](gap-analysis.md) named a signed-off register as its output and left producing one to a discovery that has never run, so every scope conversation started from a blank page. ~147 rows across 16 operational areas, buckets deliberately empty. `This app today` was checked against `app/src/` rather than taken from §4 below — which is why several catalogue promises read as absent |
| Distribution | Per-tenant extension, publisher `matr`, object range `50000..50999` |
| Environment | BC 28.1, runtime 17.0, dev container `mrt28`, production BC online W1 |
| Not started | Nothing in §4. **Every feature in the catalogue now has a first segment**, the two that stopped short of the ledger no longer do, and the queue is tied to the documents that feed it. What is unbuilt is the second segment of nine features — most of it blocked on customer facts, though **not as much as was claimed a moment ago**: see §5 |

**What is delivered was built from §4, not from a capability register.** Every shipped feature
carries that caveat in its own technical documentation. Phase 0 can still invalidate them, and
the two chosen so far were chosen precisely because they are the least likely to be invalidated
(§4, "the two that are probably not optional") and because almost everything else depends on them.

Core carries no per-feature knowledge: a feature ships by adding a `WHA Feature` enum value bound
to its own `WHA IFeatureSetup` implementation, and the wizard, the guided setup list, the MCP
registration and the deferred session restart pick it up with no Core change.

**That claim was not quite true until recently.** Five features kept their number series on
`WHA Warehouse Setup`, which meant Core knew five features by name across five files, the foundation
step read as *not started* whenever a new one shipped, and numbering for a switched-off feature was
visible on a page with no application area. Numbering now lives on each feature's own setup, with the
feature's own area, created by its own guided-setup step through the `CreateNoSeries` hook
`WHA IFeatureSetup` always had and nothing used. Core kept only the generic ability to make a series
(`WHA No. Series Mgt.`) and no longer knows which features have one.

## 2. Phase 0 — the capability register (gates everything)

Per [gap-analysis.md](gap-analysis.md). **No feature work starts until this is signed off.**

### Inputs to collect

| Input | Source | What it settles |
|---|---|---|
| Incumbent WMS module licence list | Licence file / vendor | What is *paid for* — an upper bound, not usage |
| Configuration export | Incumbent WMS admin | What is *configured* |
| 12 months of transaction volumes by document type | Incumbent WMS database | What is *actually used*, and how hard |
| ~~Current interface specification~~ **Observed interface traffic** | Message logs, database, and the people who operate the interface | The contract the replacement must satisfy. **No written specification exists** — this has to be reconstructed from what actually crosses the boundary |
| Custom report and label inventory | Incumbent WMS admin | Output formats that must be reproduced |
| Floor observation and operator interviews | On-site | Undocumented workarounds — the highest-value input |

### Classification

Every capability found lands in exactly one bucket:

- **Standard BC** — the base app already does it, possibly with configuration. Build nothing.
- **Configuration** — BC does it with setup work. Document it, build nothing.
- **Build** — a genuine gap. Becomes a `FEAT-` item.
- **Drop** — the incumbent does it, nobody uses it, or the business will change process.

**Watch the drop rate.** A low one means the analysis is not finished, not that the scope is
genuinely large. Record who approved each drop; they get re-litigated otherwise.

### Output

A signed-off capability register: one row per capability of the system being replaced, its
bucket, and for **Build** rows a target feature. That register **replaces** §4 and rewrites
[modules.md](modules.md).

A draft of it now exists — [gap-analysis.md](gap-analysis.md), *Candidate capability register*.
Every bucket in it is empty, and every row was written from outside the customer's warehouse.
It is an interview agenda, not an answer.

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
feature most likely to be judged by operators against what the incumbent already does. If handheld
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

Wave B    FEAT-TASK-001    directed work             ← segment 3 delivered; fed by receipts and shipments
          FEAT-RF-001      mobile device             ← segment 2 delivered; needs operator review

Wave C    FEAT-WAVE-001    wave management           ← segment 2 delivered; templates and a workload cap
          FEAT-PACK-001    packing                   ← segment 1 delivered
          FEAT-LBL-001     labelling                 ← segment 1 delivered

Wave D    FEAT-REPL-001    replenishment             ← segment 2 delivered; looks ahead, and schedulable
          FEAT-CNT-001     counting                  ← segment 2 delivered; adjusts on close
          FEAT-QC-001      quality hold              ← segment 2 delivered; writes off on scrap

Wave E    FEAT-SLOT-001    slotting                  ← segment 1 delivered
          FEAT-LAB-001     labour management         ← segment 1 delivered
          FEAT-DOCK-001    dock and yard             ← segment 1 delivered

Wave F    FEAT-KPI-001     analytics                 ← segment 1 delivered
```

**Every wave now has a first segment.** The catalogue is exhausted, and that is a milestone worth
reading carefully rather than celebrating: fourteen features have been built from a hypothesis, and
Phase 0 has still not been run.

Wave E changed the shape of the argument. Slotting and labour management are the first features that
add **no new warehouse operation at all** — they read what the app has already been recording since
directed work shipped, and both are worth exactly as much as that history is long. On a customer who
has not run the app yet, both produce empty screens and are correct to.

~~Two features stop deliberately short of the ledger.~~ **Both now reach it, and they reach it through
the same code.** Segment 2 of counting and segment 2 of quality hold shipped together, because they
were never two problems: a closed count sheet raising an adjustment and a scrapped pallet raising a
write-off are the same posting with a different sign and a different document.

What was built is a shared module, `app/src/Posting/`, and the argument for how it is shaped is in
[inventory-posting.md](inventory-posting.md). Three things in it are worth carrying forward:

- **It is not a feature, and saying so out loud saved the obligation set.** No toggle, no wizard step,
  no application area, no demo data, no RapidStart package — because a warehouse turns *counting* on
  and then decides what closing a sheet does, and a second switch would only create states nobody can
  explain. This is the first module in the app that is honestly a library, and the documentation says
  so rather than leaving the next reader to infer it from a missing setup page.
- **Not posting is a configured choice, not a missing feature**, and it is the value a fresh install
  and every upgrade lands on. Between "record it" and "post it" sits "put it in a journal and let
  somebody look at it", which is what a cautious warehouse actually asks for. The `WritesToLedger()`
  question exists so a sheet closed that way is honest about not being posted.
- **The gap between what is tested and what is proven got wider, not narrower.** Every decision either
  feature makes about posting is unit-tested against a recorder bound to its own enum value. Whether
  `Item Jnl.-Post Line` accepts the resulting line is tested nowhere, needs items and an open period,
  and needs the W1 container this project still does not have. Directed put-away and pick locations
  almost certainly do not work.

**With posting delivered, the largest unbuilt piece is no longer a piece of code.** It is step 1 of §8:
none of this has ever run.

Wave F closed the loop the app has been building towards since directed work: analytics measures
**nothing but what the app itself recorded**, so every figure it produces is a statement about how
much of the app the warehouse actually uses. On a company that runs none of it, all five measures
read zero and are right to.

It also produced the clearest example so far of a gap the app will not paper over. The catalogue asks
for **dock-to-stock**; nothing links a put-away to the vehicle that brought the goods, so the measure
is not shipped. What ships instead is its two halves, each honest about where its clock starts.
Closing it is a scope decision about receiving, not a reporting problem.

Wave C is where the shape of the remaining work became clear, and it is not what the wave order
suggests. Reading what all three of its features left open:

- **Labelling** cannot finish without knowing what label stock, printers and layouts exist.
- **Packing** cannot cartonise without item dimensions "nobody has confirmed this customer maintains",
  and cannot turn verification into a comparison without something to compare against.
- **Wave management** could take templates and scheduling today, and that is genuinely all of it.
  ~~Could.~~ **Delivered** — and it turned out to be worth more than the wave order suggested, because
  the workload cap it needed was already sitting in labour management. See below.

**Most of what is left in the catalogue is blocked on Phase 0, not on engineering.** That is a
different problem from the one this plan was written to sequence, and it is the strongest argument the
project has yet produced for running the capability register now.

What was buildable, and worth more than any of the above, was the thing three separate feature
documents each named as their own blocker: **the source document link**. `FEAT-TASK-001` called it
"the segment that turns this from a queue into an execution layer"; `FEAT-PACK-001` recorded that
until it existed "there is nothing to pack against"; `FEAT-KPI-001` could not ship dock-to-stock
without it. Delivered as segment 3.

Three things about it are worth carrying forward:

- **It is a button, not a subscriber.** Nothing fires on release or on posting, though subscribing to
  a Microsoft publisher was allowed and would have been easy. Until Phase 0 says how this warehouse
  receives and ships, an automatic trigger is a guess that fires by itself; a button is a guess
  somebody chose. The seam is in place, so automating it later is a one-line subscriber body.
- **It gave the app its first `pageextension`.** Nothing this project ships had ever appeared inside
  standard Business Central before. Two standard pages now carry one action each — a threshold worth
  noticing, because everything the app does is now reachable by a user who never opens one of its own
  pages.
- ~~**The link runs one way, and that is the next argument.**~~ **The decision was taken and the loop
  is closed**, behind a setting that ships off. What it changes is not the code but who owns the
  document: with it on, the quantity Business Central is about to post is one the warehouse floor
  decided. Everything about that is a customer conversation, and the switch is where it happens.

Wave management's second segment then made a point the plan had not anticipated. Its two catalogue
gaps were *templates* and *workload balancing*, and the second looked like it needed something nobody
had built — until it turned out that `FEAT-LAB-001` already held engineered standards for exactly this
work. A wave can now be capped in **minutes** instead of in lines, and no new estimation model was
invented to do it.

**That is the first time one feature's data has been used to plan rather than to measure**, and it is
the argument for the Wave E features paying for themselves. Slotting and labour management were
described as adding "no new warehouse operation at all"; this is the return on that. Two properties
were preserved deliberately: the dependency runs one way (labour knows nothing about waves), and it is
a read of *data* rather than a call into a feature — a company that never switched labour management
on has no standards, every estimate is zero, and the wave falls back to counting jobs exactly as it
did before.

Scheduling was the other half, and the decision there was to **not build one**. `WHA Wave Scheduler`
is a codeunit a job queue entry points at; the feature stores no recurrence. Business Central already
schedules things, logs failures and handles time zones, and a `Run at 06:00 daily` field here would
have been a worse version of all of it that somebody would eventually have to reconcile with the job
queue anyway.

### A correction to the paragraph above

The claim that "development has run out of things it can honestly build ahead of the register" was
made from **Wave C alone** and was too strong. Reading the remaining features properly found two
pieces of work needing no customer facts at all:

- **`FEAT-REPL-001` segment 2**, which its own documentation called "the more valuable half" of the
  catalogue entry. Delivered. It needed nothing from Phase 0 because every input is the app's own
  data: planned picks, and the wave they belong to.
- **A scheduling gap named identically by four features.** `FEAT-REPL-001`, `FEAT-SLOT-001`,
  `FEAT-LAB-001` and `FEAT-KPI-001` each recorded "a job queue entry has to be created by an
  administrator" — and none of them had a runnable codeunit for one to point at, so the work could not
  be scheduled at all. **All four are now built**, and with wave management's that is every recurring
  run in the app.

  The four are near-identical by design — a `TableNo` binding so the entry's own `Location Code`
  filter narrows the run, a `CheckEnabled` guard so an entry left behind after somebody switches a
  feature off stops rather than carrying on, and no recurrence stored anywhere. **Slotting is the one
  that is not identical**, and it is the interesting one: `Analyse` clears everything known about a
  location before it gathers, so a run that swept every location would wipe the classes of any site
  that merely had a quiet period. Its scheduler therefore **refuses a blank location filter** rather
  than inventing a sweep with a destructive edge. One entry per site is more setup; it is also the
  only honest shape.

The lesson is not that the register matters less. It is that "blocked on Phase 0" was asserted about
eleven features after reading three, and the two cheapest wins in the app were sitting in the other
eight. Read the whole list before concluding it is empty.

**That claim was then made a second time, and was wrong a second time.** After the schedulers shipped,
this section said the list "really is empty now". It was not. A further read found `FEAT-INT-001`'s
message log growing without limit — an operational hazard needing no customer fact whatsoever — and it
has since been delivered by registering the table with Business Central's own retention policy
framework.

**The pattern is worth naming, because it happened twice.** Both times the conclusion "there is
nothing left" was reached by reasoning about the *catalogue* — the fourteen features and their
segments — and both times what was actually left was not a feature at all. Scheduling was infrastructure
four features each described as somebody else's job. Retention was a table growing in the background
that no business event bounds. Neither appears in §4, so neither was found by re-reading §4.

**Then it happened a third time, from the opposite direction.** The question asked was not "what is
left to build" but "what does the incumbent do that this app does not" — and answering it produced two
deliverables in an afternoon: the draft register, and a documentation rule the repo had been breaking
since the first commit. Neither is in §4 either. The lesson generalises past this document: *the work
this project cannot see is the work no section of this project is about.* Reading §4 again will not
find it, and neither will reading §5.

**The list of catalogue work needing no customer facts is empty. The list of non-catalogue work is not,
and it is not enumerated anywhere.** What is visible from here:

| Not in the catalogue | State |
|---|---|
| ~~`FEAT-CORE-001` has no documentation~~ | **Back-filled.** It says at the top that everything but the role centre section was reconstructed by reading the objects, not taken from a design record |
| ~~The app ships no role centre and no cues~~ | **Delivered.** The guess about *who uses what* was settled by decision, not by inference: the role centre belongs to Core, and every activity on it belongs to the feature it is about |
| ~~The register has no draft, so discovery starts from a blank page~~ | **Delivered.** ~147 rows in [gap-analysis.md](gap-analysis.md), buckets empty. Found the same way as scheduling and retention were — by reading what the app *contains* rather than what the catalogue *claims*, which is how five stale catalogue promises surfaced |
| ~~The incumbent WMS is named throughout the documentation~~ | **Scrubbed.** `CLAUDE.md` forbids naming another vendor's product in this public repo and 25 mentions across six files did it anyway. The vocabulary is now "the incumbent WMS" or "the system being replaced" |
| ~~**No LICENSE**~~ | **Delivered.** Proprietary, all rights reserved: `LICENSE` grants nothing to anyone reading the public source, and [eula.md](eula.md) is the customer-facing agreement. The EULA is **draft and unreviewed**, with governing law and support terms left visibly unfilled — both are commercial decisions, and a guess there would have been worse than a gap |
| **`dmom.ai/privacy`, `/eula`, `/help` do not exist** | **Decided: leave the manifest pointing there and carry the debt.** The alternative — repointing at files in this repository — would have made the links resolve today. AppSourceCop validates URL shape only, so the build passes and the links stay dead. This closes before customer delivery, not before the next feature |
| **No CI.** `.github/workflows/` holds only a `.gitkeep` | And CI would need access to the private `bc-dev-templates` repo |
| **`app/img/AppLogo.png` is a generated placeholder** | Not real branding |
| **Customer-language getting-started files** | Deliberately deferred until a customer is engaged |

Everything remaining **in the catalogue** needs a customer fact (label stock and printers, item
dimensions, what a packer verifies against, a bin capacity model) or a scope decision (writing back to
warehouse documents, what links a vehicle visit to a put-away). Continuing to build features would
mean guessing at one of those, and every feature built that way adds unvalidated behaviour without
reducing the risk that Phase 0 invalidates it.

### A pattern worth naming: *Not done* lists go stale

Three times now a *Not done* item has described a limitation that had already been fixed —
replenishment's "nothing schedules it", analytics' "the app ships no role centre", handling units' "the
unit holds no item quantities yet". Each was true when written and false by the time somebody read it,
because the segment that fixed it updated its **own** feature's list and not the one that referenced it
from elsewhere.

That is a documentation failure with a real cost: these lists are the closest thing the project has to
a backlog, and a stale one either hides work that is done or hides work that is not. **The check is
cheap and nobody was doing it** — reading every feature's *Not done* list, not only the one being
worked on, before claiming anything about what remains.

The same sweep found the replenishment unit-of-measure hazard, which had been sitting in its own list
since segment 1 described it accurately and nobody acted on it.

### What back-filling the foundation's documentation found

Writing it required reading every Core object, which is not the same as reading the code while writing
it. Two things surfaced that no feature work would have:

- **The foundation had no tests at all.** Fourteen features depend on one mechanism — an extensible
  enum walked by ordinal — and nothing asserted that the mechanism works. Four tests now do, and one of
  them earns its place: every activity provider adds counts to a **single dictionary**, and
  `Dictionary.Add` throws on a duplicate key, so two features claiming the same cue field number would
  take the role centre down. That test is where it surfaces.
- **Three claims the document makes are still unchecked**, and it says so rather than quietly asserting
  them. One of them — that the guided setup lists every feature exactly once — would need
  `PopulateSteps` widened from `internal` to reach the test project. **Widening an API to suit a test
  is the wrong trade to make quietly**, so it was not made, and the gap is recorded instead.

The document also carries a warning worth keeping on any back-filled document: everything but the role
centre section was reconstructed from the objects rather than written from a design record, so its
"why" is a reading of the code that has held up, not a decision log. That distinction matters most to
whoever inherits it.

### What the role centre argued

Two rules were in direct tension, and the resolution is the most reusable thing in this segment.

`CLAUDE.md` says **Core carries no per-feature knowledge**. A role centre listing fourteen features'
counts would have been the largest violation of that rule in the app — and it is the shape almost every
BC app ends up with, because a cue page binds to a cue table and somebody has to own the fields.

The resolution is the seam the app already had: **an extensible enum**. Core ships
`WHA Activity Provider` with one value meaning *nothing*, and a background codeunit that walks its
ordinals asking each provider for counts. A feature contributes four objects in its **own** folder — a
`tableextension` adding its cue fields, an `enumextension` registering itself, a codeunit that counts,
and a `pageextension` that both places its fields and **declares its own background-task completion
trigger** to write them back.

That last object is what made it work without an event. A page extension can have its own
`OnPageBackgroundTaskCompleted`, so each feature writes its own counts and Core never learns a cue
field number. **A publisher was written and then deleted** once that was found — this app forbids
custom event publishers, and the seam did not need one.

Two smaller points worth keeping:

- **A switched-off feature contributes nothing, not zero.** The count implementation's first line is
  the `IsEnabled` guard, and the page fields carry the feature's application area. A tile reading zero
  would be a claim about a warehouse that is not running that feature at all.
- **Five features contribute no tile on purpose** — handling units, labelling, labour management,
  analytics and the mobile device. A cue is a count of *things that need a person today*; a label
  format is a setting, and labour and analytics are readings of history. Deciding what does **not**
  belong on a home page is most of the work of designing one.

It also exposed a documentation gap nobody had recorded: **`FEAT-CORE-001` had no docs folder at all**.
It has one now, and it says plainly that it covers the role centre and not the rest of the foundation,
which is still described only here.

### What integration's second segment argued

One thing, and it is the same argument the schedulers made: **when the platform already does something,
this app should register with it rather than reimplement it.** A bespoke message clean-up would have
needed a setup field, a scheduler, a batch size, a log and a permission set — all of which the
retention policy framework has, with a UI administrators already know and an audit trail this feature
would only have imitated badly.

What the feature *does* own is the three judgements inside the registration, each of which is a
statement about the business and not about the platform: the retention clock runs from when a message
was **processed** rather than when it arrived; the default filter covers **processed messages only**,
because a failed message is evidence; and **nothing may be kept for less than a week**, because the log
is what an argument with a partner is settled from.

### What replenishment's second segment argued

Two things worth carrying forward:

- **Demand sits beside supply, not inside it.** Segment 1 had `WHA Repl. Method` — *how is the bin
  measured*. Segment 2 added `WHA Repl. Demand` — *what is taken off it* — as a separate extensible
  enum rather than as more measurement methods. They are chosen independently because they answer
  different questions, and folding them together would have produced a combinatorial enum nobody could
  extend.
- **One judgement is stated rather than hidden.** A pick that names no source bin is counted as coming
  from the pick face. `FEAT-TASK-001` deliberately leaves that bin blank on picks raised from a
  shipment, so ignoring those picks would have made demand-aware replenishment useless in exactly the
  case it was built for. It is right in almost every warehouse and wrong where one item is picked from
  several faces at one location, and it is written down in both the technical and the user
  documentation rather than left to be discovered.

Each feature runs the greenfield loop — intake → design → document → implement → test →
deliver — **in segments**, with a test and a documentation update shipping alongside each
segment rather than batched at the end.

## 6. Cutover interaction

Undecided, and it changes the plan materially:

- **Big bang** — everything in the register must ship before cutover. Sequencing is dictated
  by the cutover date, and the drop rate in Phase 0 becomes the main lever.
- **Parallel run** — features ship incrementally while the incumbent WMS still runs.
  `FEAT-INT-001` then has to handle two systems holding stock at once, which is a substantially harder integration
  problem and should be sized accordingly.

The `Enabled` flag and per-feature application areas already support a phased rollout: a
feature can ship dark and be switched on per company when the business is ready.

## 7. Risks

| Risk | Why it matters | Mitigation |
|---|---|---|
| Scope taken from this document instead of Phase 0 | The catalogue is a hypothesis; §3 shows the cost of over-scoping | Treat §4 as an interview agenda; rewrite from the signed register |
| Handling units turn out not to be used | Invalidates the dependency spine of the catalogue | Establish it in the first Phase 0 session |
| Handheld expectations set by the incumbent | `FEAT-RF-001` is judged against a system operators already know | Prototype early with real operators |
| Undocumented customisations in the incumbent | The classic source of late scope | Floor observation and interviews, not just the config export |
| Dev container is US, production is W1 | Localisation-specific behaviour will not surface locally | Rebuild the container from a W1 artifact before posting-related work |
| Public repo needs private conventions | A fresh clone will not build; CI cannot run without access | Accepted trade; revisit if CI is introduced |
| Dead manifest URLs | `dmom.ai/privacy`, `/eula`, `/help` do not exist, and the decision is to keep pointing at them | Publish the pages before customer delivery. The content is drafted — [privacy-statement.md](privacy-statement.md) and [eula.md](eula.md) — so this is a hosting task, not a writing one |
| The EULA has unfilled clauses | Governing law and support terms are blank in [eula.md](eula.md), and neither can be inferred | Settle them commercially, then have the whole document reviewed by somebody qualified. It was drafted by a developer, and says so |

## 8. Immediate next steps

1. **Run the test suite once.** 296 automated tests exist across fourteen codeunits and **not one has
   ever been executed** — they are compile-verified only. Until they have run green once, every claim
   this project makes about its own behaviour rests on the compiler agreeing the code parses.

   This got sharper with segment 2. The app now contains code whose entire purpose is to change what
   Business Central believes is in stock, and it has never changed anything. A test run is no longer
   just overdue housekeeping.

   What is actually in the way, checked rather than assumed:

   | | |
   |---|---|
   | Container | **Up and healthy.** Web client redirects to sign-in; the development endpoint answers on port 7049 |
   | Auth mode | **NavUserPassword confirmed** — `GET :7048/BC/api/v2.0/companies` answers `401` with `Basic realm=""`. Note the API is on **7048**; asking 7049 for an API path returns `503` and means nothing |
   | Credentials | **Missing, and the only real blocker.** They are deliberately not in the repo |
   | Docker / BcContainerHelper | BcContainerHelper 6.1.11 is installed, but the Docker CLI needs an elevated shell on this machine, so `Run-TestsInBcContainer` cannot drive the container from an ordinary session |
   | Test project launch config | ~~Pointed at the template default `http://bcserver`, so F5 on `test/` could never have worked~~ — fixed; it now points at `mrt28:7049` and starts on the **AL Test Tool** (page 130451) |

   So this is one credential away, not a piece of work. Whoever has the container password can open
   `test/` and press F5.
2. **Run Phase 0.** Collect the six inputs in §2 and fill in the capability register. This is
   consulting work, not development work, and it is the highest-value thing available. It is now
   badly overdue: **all fourteen features** in the catalogue have been built from the hypothesis, and
   there is no longer a next feature whose cost the register could reduce — only rework.

   **The register itself is no longer the obstacle.** A draft exists in
   [gap-analysis.md](gap-analysis.md) — ~147 rows, every bucket empty — so the step is now *fill
   this in against the customer*, not *write it from nothing*. What it cannot supply is the part
   that was always going to be expensive: the local customisations nobody wrote down. A list
   composed from outside the warehouse cannot contain them, and it says so at the top.

   Three of its rows are worth reading before any of the others, because they invalidate what is
   already built rather than adding to it: **shelf life and FEFO** (nothing in the app refers to
   expiry), **lot and serial on directed work** (`WHA Warehouse Task` has no tracking fields, so a
   directed pick of a tracked item cannot say what it picked), and **multi-owner stock**.

   Wave C sharpened this from *overdue* to *blocking*. Reading the three features' outstanding work
   (§5) shows most of what remains cannot be designed at all without customer facts: label stock and
   printers, item dimensions, and what the warehouse expects a packer to check against. Development
   has, for the first time, run out of things it can honestly build ahead of the register.
   Replenishment sharpens the point: standard Business Central already replenishes bins through the
   movement worksheet, so a real register may reclassify part of `FEAT-REPL-001` as *configuration*
   rather than *build*.
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
