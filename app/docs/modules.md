# Module map and object ID allocation

> **Status: candidate scope, not confirmed scope.**
> The modules below are a starting hypothesis based on capabilities typically found in a
> tier-1 WMS but absent from standard Business Central. They are **not** derived from the
> customer's live installation of the incumbent WMS. Every row must be validated against what it
> actually does for this customer before any of it is built — a large share of a WMS
> footprint is usually configuration the customer never switched on.
>
> See [gap-analysis.md](gap-analysis.md) for the process of turning this into real scope.

## Folder convention

Governed by the shared conventions in `.bc-conventions/instructions/03-source-folder-layout.md`
and the greenfield structure. Source lives under `app/src/<Feature>/`, with object-type
subfolders inside each feature:

```
app/src/
├── Core/                  foundation + assisted setup (always present)
│   ├── tables/  pages/  codeunits/  enums/  interfaces/  tableextensions/
├── PermissionSet/         permission set objects for the whole app
└── <Feature>/             one folder per shipped feature, same subfolder shape
```

A feature also gets a `pageextensions/` folder when it puts something on a **standard** Business
Central page. `FEAT-TASK-001` is the first that does — its *Create warehouse tasks* action sits on
the warehouse receipt and shipment — so it is the first place this app is visible to somebody who
never opens one of its own pages. Extend a standard page only where the work genuinely starts there.

Feature folders are created **when a feature is actually scoped**, not up front — the table
below is a candidate list, not a build order.

**File name = the object name with the affix removed** and all spaces and special
characters stripped, then `.<ObjectType>.al`. Enforced by CodeCop AA0215 and LinterCop
LC0015:

```
table     "WHA Handling Unit"      -> HandlingUnit.Table.al
page      "WHA Handling Unit Card" -> HandlingUnitCard.Page.al
codeunit  "WHA Handling Unit Mgt." -> HandlingUnitMgt.Codeunit.al
permissionset "WHA WHSE - Read"    -> WHSERead.PermissionSet.al
```

The file name follows the **actual** object name including any abbreviation made to fit the
30-character cap — abbreviating the object but spelling the file out is the most common
AA0215/LC0015 trip-up.

Every object declares `namespace WarehouseAdvanced.<Feature>;` as its first line, with a
`using` for every other namespace it references, sorted alphabetically (AA0477).

All object names, fields, and extension objects carry the affix `WHA` — enforced by
`app/AppSourceCop.json`. `permissionset` names are capped at **20 characters** including
the affix.

## Object ID allocation

The app is registered for `55000..58999`. Blocks are reserved per module so parallel work
in different modules cannot collide. Test objects use `59000..59999`.

| Module | Folder | IDs | Standard BC today | Candidate gap to build |
|---|---|---|---|---|
| Foundation | `Core` | 55000–55049 | — | Setup record, guided setup hub and wizard, feature facade, permission sets, shared enums, and the generic ability to create a number series. No feature knowledge and no business logic — numbering belongs to the feature that uses it. |
| Handling units | `HandlingUnit` | 55050–55099 | No first-class pallet/container entity; item tracking is lot/serial only | License plate / SSCC-identified handling unit, nesting, move-as-one, unit history |
| Mobile device | `MobileDevice` | 55100–55149 | No RF/handheld UI; web client is desktop-shaped | Scanner-optimised page set, step-driven flows, offline-tolerant confirm, device registration |
| Wave management | `WaveManagement` | 55150–55199 | Pick worksheet, release-to-pick; no wave entity | Wave definition, release strategies, wave templates, workload balancing |
| Directed work | `DirectedWork` | 55200–55249 | Put-away templates, bin ranking, directed put-away and pick | Task queue with priority, operator assignment, task interleaving, travel-path sequencing |
| Replenishment | `Replenishment` | 55250–55299 | Bin replenishment via movement worksheet | Demand-driven and min/max replenishment triggers, wave-aware pre-replenishment |
| Slotting | `Slotting` | 55300–55349 | Static bin ranking / warehouse classes | Velocity (ABC) analysis, slotting proposals, re-slotting worksheet |
| Labour management | `LabourManagement` | 55350–55399 | None | Engineered standards, operator performance, indirect time capture |
| Packing | `Packing` | 55400–55449 | Basic shipment posting | Packing station UI, cartonisation, pack verification, packing list output |
| Dock & yard | `DockYard` | 55450–55499 | None | Dock door master, appointment/slot booking, trailer and yard position tracking |
| Counting | `Counting` | 55500–55549 | Physical inventory journal, warehouse physical inventory | Perpetual cycle counting by ABC/trigger, count tolerance and approval, blind counts |
| Quality hold | `QualityHold` | 55550–55599 | Blocked items, bin blocking | Quarantine workflow, inspection disposition, hold/release audit trail |
| Labelling | `Labelling` | 55600–55649 | Basic report layouts | GS1-128 / SSCC generation, label templates, printer routing per zone |
| Integration | `Integration` | 55650–55699 | Standard APIs | API pages and event contracts for the replacement interface and downstream automation |
| Analytics | `Analytics` | 55700–55749 | Standard warehouse reports | Operational KPI queries, throughput and dock-to-stock measures |
| Posting | `Posting` | 55750–55799 | Item journal, physical inventory journal | A shared way for any feature to change what Business Central believes is in stock, chosen per feature: not at all, a journal line somebody posts, or straight to the ledger. **Not a feature** — no toggle, no wizard step, no application area of its own |
| Warehouse registration | `Registration` | 55800–55849 | Warehouse journal, warehouse activity registering | A shared way for any feature to tell Business Central what happened to the goods in a bin — moved between two bins, added to one, or taken out of one. A move is chosen per feature; an adjustment is the other half of writing to the item ledger and is not optional. **Not a feature** — no toggle, no wizard step, no application area of its own |
| Telemetry | `Telemetry` | 55850–55899 | Application Insights, `Feature Telemetry` | A shared way for the app's unattended runs to say what they did. **Not a feature** — no toggle, no wizard step, no application area of its own. Emits system metadata only, by the shape of its procedures |
| _reserved_ | — | 55900–58999 | — | Unallocated headroom |

## Sequencing note

`Foundation`, `HandlingUnit`, and `Integration` are load-bearing — most other modules
depend on them. `MobileDevice` should follow `DirectedWork`, since the handheld flows are
a presentation layer over the task queue rather than a separate feature.
