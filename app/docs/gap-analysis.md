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
| Incumbent WMS module licence list | Customer's licence file / vendor | Which modules are *paid for* — an upper bound, not usage |
| Configuration export | Incumbent WMS admin | Which are *configured* — closer to reality |
| 12 months of transaction volumes by document type | Incumbent WMS database | Which are *actually used*, and how hard |
| Interface specification (current) | Existing integration | The contract the replacement must satisfy |
| Custom report and label inventory | Incumbent WMS admin | Output formats that must be reproduced |
| Floor observation / operator interviews | On-site | Undocumented workarounds — the highest-value input |

## Classification

Each capability found lands in exactly one bucket:

- **Standard BC** — covered by the base app, possibly with configuration. Build nothing.
- **Configuration** — covered by BC with setup work. Document it, build nothing.
- **Build** — genuine gap. Goes into a module in `modules.md` with an ID block.
- **Drop** — the incumbent does it, nobody uses it, or the business is willing to change process.
  Record the decision and who made it; these get re-litigated later otherwise.

The **Drop** column is the one that determines whether this project is deliverable. Treat
a low drop rate as a sign the analysis is not finished.

## Output

A signed-off capability register: one row per capability of the system being replaced, its
bucket, and for **Build** rows a target module. That register supersedes the candidate table in
`modules.md`, which should then be rewritten to match it.

A **draft** of it follows, with every bucket left empty. It exists so the discovery starts from a
list somebody can argue with rather than from a blank page. It is not the output — the output is
that draft filled in, corrected, extended, and signed.
## Candidate capability register — DRAFT, buckets deliberately empty

This is the register the section above asks for, pre-populated so the discovery conversation
starts from a list rather than a blank page.

**Read the warning before using it.** The rows are the functional footprint a tier-1 WMS of the
incumbent's class typically ships, cross-read against what `app/src/` contains today. They are
**not** derived from the customer's installation, no licence file or configuration export has
been seen, and no operator has been interviewed. *A row existing here is not evidence that the
customer uses it, and the list is certainly not complete* — the capabilities that hurt are the
local customisations nobody wrote down, and none of those can be in a list written from outside.

### How to fill it in

- **One bucket per row**, from the four in [Classification](#classification). A row with two
  buckets is a row that has not been understood yet.
- **"This app today" is a claim about code**, checked against `app/src/` when the register was
  written. It goes stale — see the *Not done* lists lesson in
  [implementation-plan.md](implementation-plan.md). Re-check before trusting a row.
- **A Build row needs a target feature.** An existing mark, or a new one with an ID block
  allocated in [modules.md](modules.md).
- **A Drop row needs a named approver** in the sign-off table at the end. Unattributed drops get
  re-litigated six months later, by somebody who was not in the room.
- **Add rows.** The list is a floor, not a ceiling. Every row discovery adds is worth more than
  every row it confirms.
- **Watch the drop rate.** A low one means the analysis is not finished.

### 1. Inbound

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Advance shipping notice inbound | None | None — no message type for it | | |
| Receipt against an expected quantity | Warehouse receipt against order | Tasks raised from a warehouse receipt | | |
| Blind receiving | Warehouse receipt | None | | |
| Receiving by pallet identity | None | Handling unit, created by message or by hand | | |
| Supplier barcode capture (GS1-128 read) | None | Code *generation* only; nothing parses a barcode | | |
| Cross-docking / flow-through | None | None | | |
| Customer return receipt | Return order, return receipt | None on the warehouse side | | |
| Inspection or sampling at receipt | None | Quality hold applies only once a unit exists | | |
| Put-away by rule or template | Put-away templates, bin ranking | A put-away task type; no template engine | | |
| Put-away fit check (does it go in the bin) | Bin capacity, if maintained | None — a bin is chosen without asking | | |
| Dock-to-stock elapsed time | None | Two halves shipped; nothing links a put-away to a vehicle | | |

### 2. Storage model and warehouse master data

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Warehouse topology (zone, aisle, rack, level, depth) | Location, zone, bin, bin type | Uses BC bins as they are; no topology of its own | | |
| Bin capacity by weight or volume | Max. cubage and weight on the bin | Not read anywhere | | |
| Item warehouse attributes (dimensions, tare, stackability) | Unit-of-measure dimensions | None | | |
| Handling class per item | None | None | | |
| Mixed-item and mixed-lot bin rules | Bin type, block movement | None | | |
| Storage conditions (temperature, humidity) | None | None | | |
| Segregation and incompatibility rules | None | None | | |
| Dangerous goods classification and handling | None | None | | |
| Catch weight / variable weight | None | None | | |
| Handling unit type master (pallet type, tare, max layers) | None | None — the unit has no type, capacity or dimensions | | |
| Handling unit nesting | None | Parent and child, with a nested count | | |
| Handling unit history and genealogy | None | Status only; no movement history | | |
| Equipment and forklift register | None | An RF device register, which is not the same thing | | |

### 3. Allocation and item tracking

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Lot or serial captured on directed work | Item tracking on activity lines | **None** — the warehouse task has no tracking fields | | |
| Expiry date held on stock | Item tracking, expiration date | **Nothing in the app refers to expiry at all** | | |
| Shelf-life rules | Strict expiry posting | None | | |
| FEFO allocation | Pick according to FEFO | None | | |
| Minimum remaining shelf life at picking, per customer | None | None | | |
| Allocation strategy per item or customer | Reservation, picking rules | None | | |
| Held stock excluded from allocation | Blocked lot | A hold stops the unit; nothing filters allocation | | |
| Reservation or soft allocation against an order | Reservation entries | Replenishment reads planned picks; reserves nothing | | |
| Stock ownership / multi-owner segregation | None | None | | |
| Traceability up and down a lot, for a recall | Item tracing | None | | |

### 4. Directed work and picking

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Task queue with priority | Warehouse activity lines | Delivered | | |
| Operator assignment | None | Assigned-to user, with timestamps | | |
| Partial completion with a reason | Partial handling on the line | Delivered | | |
| Travel-path sequencing | Sorting by bin ranking | **None** — the task carries nothing spatial | | |
| Task interleaving | None | **None** | | |
| Batch, cluster or multi-order picking | Pick worksheet consolidation | None | | |
| Zone picking with handover | Zone-based activities | None | | |
| Pick to cart, with a trolley position | None | None | | |
| Pick face against bulk | Bin ranking plus replenishment | Replenishment rules per pick bin | | |
| Work raised from a production order | Warehouse pick for production | None — the sources are receipt, shipment, manual | | |
| Completion written back to the source document | Native | **None — the link runs one way** | | |
| Supervisor cancel and re-queue | Delete the line | A status model, but no supervisor console | | |

### 5. Wave, replenishment, slotting

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Wave definition and release | Release to pick | Delivered | | |
| Wave templates | None | Delivered | | |
| Workload cap in minutes of work | None | Delivered, from labour standards | | |
| Wave simulation before release | None | None | | |
| Cartonisation at wave time | None | None | | |
| Min/max replenishment per pick bin | Movement worksheet | Delivered, converted through the base unit | | |
| Demand-driven replenishment | None | Delivered, from planned picks | | |
| Wave-aware pre-replenishment | None | Delivered | | |
| ABC velocity analysis | Static warehouse classes | Delivered, from the app's own pick history | | |
| Slotting proposals | None | Delivered; a proposal can raise a task | | |
| Affinity, seasonality, ergonomic placement | None | None | | |

### 6. Packing and outbound

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Packing station and session | None | Delivered | | |
| Cartonisation | None | **None** — needs item dimensions nobody has confirmed | | |
| Pack verification against the order | None | A status change; there is nothing to compare against | | |
| Packaging material consumption | None | None | | |
| Packing list output | Report layouts | **None — the app ships no report objects at all** | | |
| Delivery note, CMR, bill of lading | Standard reports | None from this app | | |
| Load planning and load sequence | None | None | | |
| Staging bin management | Bin types for ship and receive | None | | |
| Loading control and load verification | Shipment posting | None | | |
| Shipment consolidation | Combine shipments | None | | |
| Parcel carrier integration and parcel labels | None | None | | |

### 7. Labelling and printing

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| SSCC with its check digit | None | Delivered | | |
| Sequential licence plate | None | Delivered | | |
| Label templates and layouts | Report layouts | **None** | | |
| Barcode symbologies (GS1-128, DataMatrix, QR) | Barcode fonts in reports | None — the app produces a code, not a label | | |
| Printer master and routing per zone or station | Printer selection | **None** | | |
| Reprint, with an audit of who reprinted | None | None | | |
| The customer's existing label formats | — | Unknown; a Phase 0 input | | |

### 8. Dock and yard

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Dock door master | None | Delivered | | |
| Appointment or slot booking | None | Delivered | | |
| Door selection strategy | None | Two, swappable | | |
| Yard positions and trailer tracking | None | Delivered | | |
| Gate check-in and check-out, driver and vehicle | None | None | | |
| Trailer seal control | None | None | | |
| Weighbridge | None | None | | |
| Door calendar and capacity by hour | None | None | | |
| Yard moves raised as directed work | None | None | | |
| Carrier notification or self-service booking | None | None | | |

### 9. Quality

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Hold a handling unit and everything on it | Blocked item or lot, bin blocking | Delivered | | |
| Dispositions: release, rework, scrap, pending | None | Delivered | | |
| Write-off on scrap | Item journal | Delivered — **never yet run against the ledger** | | |
| Hold audit trail that cannot be deleted | Change log | Delivered | | |
| Inspection plans and sampling | None | None | | |
| Recorded results and certificates | None | None | | |
| Supplier quality | Vendor statistics | None | | |
| Recall execution | Item tracing | None | | |

### 10. Counting

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Count sheets by bin or by handling unit | Physical inventory journal | Delivered | | |
| Blind counting | Partly | Delivered | | |
| Tolerance and variance approval | None | Delivered | | |
| Posting the difference | Physical inventory journal | Delivered — **never yet run against the ledger** | | |
| Counting by lot or serial | Item tracking | Fields exist on the count line | | |
| ABC- or event-driven count triggering | Counting periods | **None** — counting is the one feature with no scheduler | | |
| Recount cycle | Recount on the journal | None | | |

### 11. Mobile and operator interaction

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Handheld screen and device register | None | Delivered | | |
| Step-driven scan flow, swappable | None | One flow, seven steps, no operator has seen it | | |
| Flows for receiving, packing, counting, loading, enquiry | None | **None — the handheld does directed work only** | | |
| Offline-tolerant confirm | None | **None** — named in the catalogue, not built | | |
| Flow configured per role or per device | None | None | | |
| Operator screen language | BC translations | English only; the customer language is deferred | | |
| Pick by voice | None | None | | |
| Pick to light, put to light | None | None | | |
| RFID and real-time location | None | None | | |
| Wearables and ring scanners | None | None | | |

### 12. Labour and workforce

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Engineered standards | None | Delivered — fixed, and fixed plus per unit | | |
| Completed work turned into measured time | None | Delivered | | |
| Indirect time capture | None | Delivered | | |
| Operator performance against standard | None | Partly, through the KPI snapshots | | |
| Shifts and rosters | None | None | | |
| Capacity planning by shift | None | A wave cap in minutes, and nothing else | | |
| Incentive pay | None | None | | |
| Standards that vary with travel distance | None | None — no distance model exists to vary with | | |

### 13. Reporting and analytics

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Operational KPI snapshots | None | Five measures, delivered | | |
| Dock-to-stock | None | **Not shipped** — nothing links a put-away to a vehicle | | |
| Ad-hoc analysis and drill-down | Analysis views, Power BI | Nothing from this app | | |
| Real-time floor dashboard | None | Role centre cues | | |
| Alerting and escalation on an exception | Notifications, job queue | None | | |
| Warehouse map or visualisation | None | None | | |
| Activity reporting fit to bill from | None | None | | |

### 14. Integration and automation

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Message spine with handler dispatch | None | Delivered | | |
| Message log retention | Retention policy framework | Delivered | | |
| The four message types built so far | — | Delivered **on assumed contracts** | | |
| The real contract of the interface being replaced | — | **Unknown, and no specification exists** | | |
| EDI documents (despatch advice, orders, receiving advice) | None | None | | |
| Conveyor, sorter, crane, AGV control | None | None | | |
| Scale, weighbridge, print server, PLC endpoints | None | None | | |
| API surface for downstream automation | Standard APIs | An API page per persisted table | | |
| The automation planned "on top of" the WMS | — | Unspecified; an open question below | | |

### 15. Adjacent modules the incumbent may licence

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Transport management: carriers, rates, routes, freight cost | None | None | | |
| Proof of delivery and shipment tracking | None | None | | |
| Vendor-managed inventory | None | None | | |
| Production supply: kanban, milkrun, line feeding | Warehouse pick for production | None | | |
| Shop-floor control | Production orders | None | | |
| Activity-based billing for logistics services | None | None | | |
| Multi-client warehousing | None | None | | |

### 16. Administration, security, audit

| Capability | Standard BC today | This app today | Bucket | Target |
|---|---|---|---|---|
| Feature toggles and guided setup | Assisted setup | Delivered | | |
| Permission sets | Native | Delivered, per object as it is created | | |
| Rights per zone or per task type | Permission sets, warehouse employee | None | | |
| Supervisor override, with a reason | None | None | | |
| Electronic signature on a disposition | None | None | | |
| Change log on warehouse master data | Change log | Not configured by this app | | |
| Demo data and configuration packages | Native | Delivered, per feature | | |

### The three rows to settle first

Not the largest rows — the ones that **invalidate what is already built** rather than adding to it:

1. **Shelf life and FEFO.** Nothing in the app refers to expiry. If this warehouse handles dated
   stock, allocation, picking, counting and quality all change shape rather than gain a field.
2. **Lot and serial on directed work.** The task has no tracking fields, so a directed pick of a
   tracked item cannot say what it picked. That breaks traceability *and* posting.
3. **Multi-owner stock.** If inventory here belongs to more than one party, it is a data model
   decision reaching every table in the app, and it cannot be retrofitted cheaply.

### Sign-off

The register is not an input to anything until this table is filled in.

| | |
|---|---|
| Register version | Draft — buckets empty, no discovery input received |
| Inputs received | None of the six in [Inputs to collect](#inputs-to-collect) |
| Filled in by | |
| Approved by | |
| Date | |

Drops, recorded one by one, because they are the rows that get re-opened:

| Capability | Approved by | Date | Reason, and what the business does instead |
|---|---|---|---|
| | | | |


## Decisions taken

- **Distribution: per-tenant extension (PTE).** Not AppSource. The `50000..50999` range
  and the `WHA` affix therefore stand as-is — no ID range or affix registration with
  Microsoft is required. The affix is kept anyway: it prevents collision with other
  extensions installed in the same tenant, which is a real risk in a customer environment,
  not just an AppSource formality.
- **Production localisation: W1.** No country localisation.

## Open questions

- [ ] What is the cutover model — big bang, or does the new app run alongside the incumbent WMS?
- [ ] Which automation is planned "on top of" the WMS solution, and does it consume the
      `Integration` module's API surface or drive the UI?

## Known environment mismatch

The dev container is built from a **US** sandbox artifact, but production is **W1**. For
warehouse objects the overlap is high and the risk is low, so this is not urgent — but it
is not zero either, and the honest fix is to rebuild the container from a W1 artifact
before serious work on modules that touch posting or documents.
