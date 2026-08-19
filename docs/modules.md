# Module map and object ID allocation

> **Status: candidate scope, not confirmed scope.**
> The modules below are a starting hypothesis based on capabilities typically found in a
> tier-1 WMS but absent from standard Business Central. They are **not** derived from the
> customer's live Qguar installation. Every row must be validated against what Qguar
> actually does for this customer before any of it is built — a large share of a WMS
> footprint is usually configuration the customer never switched on.
>
> See [gap-analysis.md](gap-analysis.md) for the process of turning this into real scope.

## Folder convention

Source lives under `app/src/<Module>/`, flat within each module (the convention used by
Microsoft's own Base Application). One object per file:

```
<ObjectName>.<ObjectType>.al      e.g. WHAHandlingUnit.Table.al
                                       WHAHandlingUnitCard.Page.al
                                       WHAHandlingUnitMgt.Codeunit.al
```

All object names, fields, and extension objects carry the affix `WHA` — enforced by
`app/AppSourceCop.json`.

## Object ID allocation

The app is registered for `50000..50999`. Blocks are reserved per module so parallel work
in different modules cannot collide. Test objects use `51000..51999`.

| Module | Folder | IDs | Standard BC today | Candidate gap to build |
|---|---|---|---|---|
| Foundation | `Foundation` | 50000–50049 | — | Setup table, permission sets, shared enums, number series, base events. No business logic. |
| Handling units | `HandlingUnit` | 50050–50099 | No first-class pallet/container entity; item tracking is lot/serial only | License plate / SSCC-identified handling unit, nesting, move-as-one, unit history |
| Mobile device | `MobileDevice` | 50100–50149 | No RF/handheld UI; web client is desktop-shaped | Scanner-optimised page set, step-driven flows, offline-tolerant confirm, device registration |
| Wave management | `WaveManagement` | 50150–50199 | Pick worksheet, release-to-pick; no wave entity | Wave definition, release strategies, wave templates, workload balancing |
| Directed work | `DirectedWork` | 50200–50249 | Put-away templates, bin ranking, directed put-away and pick | Task queue with priority, operator assignment, task interleaving, travel-path sequencing |
| Replenishment | `Replenishment` | 50250–50299 | Bin replenishment via movement worksheet | Demand-driven and min/max replenishment triggers, wave-aware pre-replenishment |
| Slotting | `Slotting` | 50300–50349 | Static bin ranking / warehouse classes | Velocity (ABC) analysis, slotting proposals, re-slotting worksheet |
| Labour management | `LabourManagement` | 50350–50399 | None | Engineered standards, operator performance, indirect time capture |
| Packing | `Packing` | 50400–50449 | Basic shipment posting | Packing station UI, cartonisation, pack verification, packing list output |
| Dock & yard | `DockYard` | 50450–50499 | None | Dock door master, appointment/slot booking, trailer and yard position tracking |
| Counting | `Counting` | 50500–50549 | Physical inventory journal, warehouse physical inventory | Perpetual cycle counting by ABC/trigger, count tolerance and approval, blind counts |
| Quality hold | `QualityHold` | 50550–50599 | Blocked items, bin blocking | Quarantine workflow, inspection disposition, hold/release audit trail |
| Labelling | `Labelling` | 50600–50649 | Basic report layouts | GS1-128 / SSCC generation, label templates, printer routing per zone |
| Integration | `Integration` | 50650–50699 | Standard APIs | API pages and event contracts for the replacement interface and downstream automation |
| Analytics | `Analytics` | 50700–50749 | Standard warehouse reports | Operational KPI queries, throughput and dock-to-stock measures |
| _reserved_ | — | 50750–50999 | — | Unallocated headroom |

## Sequencing note

`Foundation`, `HandlingUnit`, and `Integration` are load-bearing — most other modules
depend on them. `MobileDevice` should follow `DirectedWork`, since the handheld flows are
a presentation layer over the task queue rather than a separate feature.
