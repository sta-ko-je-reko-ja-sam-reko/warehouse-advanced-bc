# FEAT-CORE-001 - Foundation

## Source/legacy reference

N/A (greenfield).

> **This folder is new, and it is not a full record of the foundation.** `FEAT-CORE-001` shipped in
> PRs #5–#7 without documentation of its own — the setup record, guided setup hub, per-feature wizard,
> feature facade and permission sets are described in [../implementation-plan.md](../implementation-plan.md)
> and nowhere else. This document covers the **role centre**, added later, and states the gap rather
> than pretending the folder is complete. Back-filling the rest is worth doing and has not been done.

## Business process

Everything this app does happens somewhere else: a job on the queue, a sheet on the floor, a pallet on
hold. Until now there was no page that answered the question a warehouse manager actually starts the
day with — **what needs me?**

The role centre answers it, and it is the one page in the app that is about the app as a whole.

### Delivered so far

**The role centre and the activity seam** — a home page owned by the foundation, whose tiles are
contributed by the features themselves.

## The shape, and why

Two rules were in tension.

- `CLAUDE.md`: **Core carries no per-feature knowledge.** A role centre that named fourteen features'
  tables would be the largest violation of that rule in the app.
- `_patterns/role-center-cues.md`: cue counts must be computed in a **page background task**, against a
  **`TableType = Temporary`** cue table with **plain `Integer`** fields — never FlowFields, so the home
  page opens instantly.

The resolution is the same seam the rest of the app uses: **an extensible enum, and every feature
contributes to it.**

| Object | Type | Owner | Purpose |
|---|---|---|---|
| `WHA Activities Cue` | table 50003 | Core | The temporary row the tiles bind to. **Ships with no cue fields of its own** |
| `WHA IActivityCues` | interface | Core | `AddCounts(var Results)` — one method |
| `WHA Activity Provider` | enum 50002 | Core | Extensible. Core's only value is `WHANone` |
| `WHA No Activity Cues` | codeunit 50008 | Core | Counts nothing. The foundation does no warehouse work |
| `WHA Activities Cue Calc` | codeunit 50009 | Core | Walks the enum's ordinals, asks each provider, returns the results |
| `WHA Warehouse Activities` | page 50003 | Core | The cue part. Enqueues the task; its `cuegroup` is **empty** |
| `WHA Warehouse Manager RC` | page 50004 | Core | The role centre |
| `WHA Warehouse Manager` | profile | Core | Makes it selectable |

**Core names no feature anywhere in that list.** `WHA Activities Cue Calc` iterates
`Enum::"WHA Activity Provider".Ordinals()` exactly as `WHA Feature Mgt.GetEnabledFingerprint` iterates
`WHA Feature` — a mechanism the app already had.

### What a feature contributes

Four objects, all inside the feature's own folder and ID block:

1. a **`tableextension`** on `WHA Activities Cue`, adding its own `Integer` cue fields;
2. an **`enumextension`** on `WHA Activity Provider`, binding a value to its own implementation;
3. a **`codeunit`** implementing `WHA IActivityCues`, which counts;
4. a **`pageextension`** on `WHA Warehouse Activities`, adding its fields to the cuegroup **and its own
   `OnPageBackgroundTaskCompleted` trigger** to write the returned counts onto the row.

That fourth object is the part worth knowing. A page extension can declare its own background-task
completion trigger, so **each feature writes its own counts** and the foundation never learns a single
cue field number. The alternative — Core raising an event for features to subscribe to — was written
and then deleted: this app forbids custom event publishers, and the seam did not need one.

### Feature toggles are respected twice

- On the **page**: every cue field carries its feature's `ApplicationArea`, so a switched-off feature's
  tiles are not rendered.
- In the **count**: every implementation's first line is `FeatureMgt.IsEnabled(...)`, and a
  switched-off feature adds **nothing at all** to the results — not a zero. A zero would be a claim
  about a warehouse that is not running that feature.

## Who contributes what

| Feature | Tiles |
|---|---|
| `FEAT-TASK-001` | Jobs waiting, jobs being done, jobs past their date |
| `FEAT-WAVE-001` | Waves being built, waves on the floor |
| `FEAT-CNT-001` | Count sheets on the floor, counts waiting for approval |
| `FEAT-QC-001` | Goods on hold, holds waiting for a decision |
| `FEAT-PACK-001` | Cartons being packed |
| `FEAT-DOCK-001` | Vehicles on site, vehicles waiting for a door |
| `FEAT-INT-001` | Messages waiting, messages that failed |
| `FEAT-REPL-001` | Replenishment rules switched off |
| `FEAT-SLOT-001` | Slotting proposals waiting |

**Five features contribute nothing, on purpose.** Handling units, labelling, labour management,
analytics and the mobile device have no tile, because a cue is a count of *things that need a person
today*. A handling unit is not outstanding work; a label format is a setting; labour and analytics are
readings of history, which is what their own pages are for; and the handheld is used by somebody who
is not looking at a role centre.

## Tests

The cue implementations belong to features, so their tests do too. `WHA Warehouse Task Tests` asserts
that released work is counted and that a switched-off feature contributes **no keys at all**;
`WHA Quality Hold Tests` asserts that goods on hold and holds waiting for a decision are two different
numbers.

The background task itself is not unit-tested: `Page.SetBackgroundTaskResult` needs a page session.
What is tested is every implementation that feeds it, which is where the logic lives.

## Not done

- **The role centre has almost no navigation.** It carries the guided setup and the foundation setup,
  and everything else is reached by drilling into a tile or by search. Feature-owned navigation would
  be a second `pageextension` per feature on the role centre, and it is not built.
- **No headline, no charts, no report links.** The page is a cue part and a setup section.
- **One role centre, and it is the manager's.** There is no operator profile; `FEAT-RF-001` is what an
  operator uses, and it has still never been seen by one.
- **No targets or colours.** A tile shows a number. Nothing is red for being bad, because nothing knows
  what good looks like — the same gap `FEAT-KPI-001` records.
- **The rest of the foundation is undocumented**, as the note at the top says.
