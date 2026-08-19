# FEAT-CORE-001 - Foundation

## Source/legacy reference

N/A (greenfield).

> **This folder was back-filled.** `FEAT-CORE-001` shipped in PRs #5–#7 with no documentation of its
> own; the role centre was added later and documented on arrival. Everything above the *Role centre*
> section was written afterwards by reading the objects, not from a design record — so it describes
> what the foundation **does**, and where it states *why*, that reasoning is reconstructed rather than
> contemporaneous. Treat the "why" as a reading of the code that has held up, not as a decision log.

## What the foundation is for

Every other feature in this app is a warehouse capability. The foundation is not: it is the machinery
that lets fourteen of them be switched on independently, set up in a sensible order, and reach an
agent — **without the foundation knowing any of them by name.**

That is the constraint the whole module exists to satisfy, and it is the one thing worth checking on
any change to it. `CLAUDE.md` states it as a rule; this document explains how it is kept.

## The single mechanism

Everything below is the same idea applied four times: **an extensible enum whose values bind to
interface implementations, walked by ordinal.**

```
enum "WHA Feature"            implements "WHA IFeatureSetup"    → setup, toggle, wizard, MCP
enum "WHA Activity Provider"  implements "WHA IActivityCues"    → role centre tiles
```

A feature ships by **adding an enum value**. No Core object changes. The guided setup list, the
wizard, the MCP registration, the deferred session restart and the role centre all pick it up because
they iterate `Ordinals()` rather than naming anything.

`WHA Feature Mgt.GetEnabledFingerprint` is the clearest example: it walks every feature and asks each
whether it is on, without a single branch.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Warehouse Setup` | 50000 | The foundation's own single-record setup |
| `WHA Setup Step` | 50001 | **`TableType = Temporary`.** One row per step in the guided setup list |
| `WHA Demo Data` | 50002 | Records which sample data sets have been loaded, so importing twice creates nothing |
| `WHA Activities Cue` | 50003 | **`TableType = Temporary`.** The row the role centre tiles bind to |

### `WHA Warehouse Setup` holds almost nothing, on purpose

One field: `Primary Key`. It once held the number series for five features; those moved to the
features' own setups because Core knowing five features by name across five files was the rule being
broken in the least visible way. What is left is a record whose existence marks that the foundation
step has been run.

### `WHA Setup Step` is a buffer, not a table

It is built fresh each time the setup hub opens, by asking every feature to describe itself. Nothing
is stored, so a step cannot go stale and a feature cannot leave a row behind when it is removed.

| Field | Notes |
|---|---|
| `Step No.` | The order steps are shown in. Each feature chooses its own number |
| `Feature` | The enum value, which is how the hub calls back into the feature |
| `Has Toggle` | False for the foundation step, which is always on |
| `Has No. Series` | Whether the wizard offers to create numbering. **The foundation does not know which series** — only that the feature says it has one |
| `Name`, `Description`, `Setup Page ID` | Supplied by the feature, shown by the hub |
| `Enabled`, `Status` | Computed when the list is built |

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Warehouse Setup` | table | 50000 | `app/src/Core/tables/WarehouseSetup.Table.al` |
| `WHA Setup Step` | table | 50001 | `app/src/Core/tables/SetupStep.Table.al` |
| `WHA Demo Data` | table | 50002 | `app/src/Core/tables/DemoData.Table.al` |
| `WHA Activities Cue` | table | 50003 | `app/src/Core/tables/ActivitiesCue.Table.al` |
| `WHA Feature` | enum | 50000 | `app/src/Core/enums/Feature.Enum.al` |
| `WHA Setup Step Status` | enum | 50001 | `app/src/Core/enums/SetupStepStatus.Enum.al` |
| `WHA Activity Provider` | enum | 50002 | `app/src/Core/enums/ActivityProvider.Enum.al` |
| `WHA IWarehouseSetup` | interface | — | `app/src/Core/interfaces/IWarehouseSetup.Interface.al` |
| `WHA IFeatureSetup` | interface | — | `app/src/Core/interfaces/IFeatureSetup.Interface.al` |
| `WHA IActivityCues` | interface | — | `app/src/Core/interfaces/IActivityCues.Interface.al` |
| `WHA Warehouse Setup Logic` | codeunit | 50000 | `app/src/Core/codeunits/WarehouseSetupLogic.Codeunit.al` |
| `WHA Feature Mgt.` | codeunit | 50001 | `app/src/Core/codeunits/FeatureMgt.Codeunit.al` |
| `WHA Guided Setup` | codeunit | 50002 | `app/src/Core/codeunits/GuidedSetup.Codeunit.al` |
| `WHA Install` | codeunit | 50003 | `app/src/Core/codeunits/Install.Codeunit.al` |
| `WHA Upgrade` | codeunit | 50004 | `app/src/Core/codeunits/Upgrade.Codeunit.al` |
| `WHA Default Feature Setup` | codeunit | 50005 | `app/src/Core/codeunits/DefaultFeatureSetup.Codeunit.al` |
| `WHA MCP Setup` | codeunit | 50006 | `app/src/Core/codeunits/MCPSetup.Codeunit.al` |
| `WHA No. Series Mgt.` | codeunit | 50007 | `app/src/Core/codeunits/NoSeriesMgt.Codeunit.al` |
| `WHA No Activity Cues` | codeunit | 50008 | `app/src/Core/codeunits/NoActivityCues.Codeunit.al` |
| `WHA Activities Cue Calc` | codeunit | 50009 | `app/src/Core/codeunits/ActivitiesCueCalc.Codeunit.al` |
| `WHA Warehouse Setup` | page | 50000 | `app/src/Core/pages/WarehouseSetup.Page.al` |
| `WHA Setup Hub` | page | 50001 | `app/src/Core/pages/SetupHub.Page.al` |
| `WHA Feature Setup Wizard` | page | 50002 | `app/src/Core/pages/FeatureSetupWizard.Page.al` |
| `WHA Warehouse Activities` | page | 50003 | `app/src/Core/pages/WarehouseActivities.Page.al` |
| `WHA Warehouse Manager RC` | page | 50004 | `app/src/Core/pages/WarehouseManagerRC.Page.al` |
| `WHA Warehouse Manager` | profile | — | `app/src/Core/profiles/WarehouseManager.Profile.al` |
| `WHA Objects` / `WHA Full` / `WHA Read` | permissionset | 50000–50002 | `app/src/PermissionSet/` |

All in namespace `WarehouseAdvanced.Core`, from the reserved block `50000..50049`.

**The permission sets are the one place the foundation does name every feature**, and unavoidably: a
permission set lists objects. They are in `app/src/PermissionSet/` rather than in `Core/` for that
reason — they belong to the app, not to the foundation.

## `WHA IFeatureSetup` — what a feature must answer

Four methods, and the shape of each is a decision:

| Method | Contract |
|---|---|
| `RegisterStep` | Describe yourself into the buffer. A feature with nothing to configure leaves it untouched |
| `IsEnabled` | Read your own setup record. **Not cached** — the remark in `WHA Feature Mgt.` says the flag is safe to cache because changing it restarts the session, but the code reads every time |
| `ApplyChoices` | Apply the wizard's answers. **Must not restart the session** |
| `RegisterMcpConfiguration` | Create or refresh your MCP configuration. **Must be idempotent** — it runs on install *and* upgrade |

`WHA Default Feature Setup` implements all four as no-ops, and is the enum's `DefaultImplementation`.
A new enum value that forgets its binding therefore does nothing rather than failing.

### The restart is owned by the hub, not by the feature

Changing an application area needs a session restart. If each feature restarted after applying its own
choices, setting up five features would restart five times and the user would never reach the end of
the list. So `ApplyChoices` is forbidden from restarting, the hub restarts **once** when the list
closes, and the standalone setup pages compare an enabled-state fingerprint on open and close to
decide whether a restart is owed at all.

## The guided setup

`WHA Setup Hub` is a list over the temporary buffer. `PopulateSteps` adds the foundation step, then
asks every feature enum value to add its own, then computes statuses. `WHA Feature Setup Wizard` is a
`NavigatePage` with three steps — about, choices, done — and hands the answers back through
`ApplyChoices`.

`RegisterAssistedSetup` puts the hub into Business Central's own **Assisted Setup** list, so it is
found where a user looks for setup rather than only by search. `WHA Install` and `WHA Upgrade` both
call it, along with `EnsureConfigurations` for MCP — which is why `RegisterMcpConfiguration` has to be
idempotent.

## MCP registration

`WHA MCP Setup` wraps the platform's MCP configuration tables: create a configuration, add API pages
as tools with per-tool create/modify/delete flags, activate it. Every feature calls it from
`RegisterMcpConfiguration` with its own configuration name and its own API pages.

The per-tool flags are how the app expresses **what an agent may do**, and the features use them with
deliberate asymmetry — a count sheet line is read-only to an agent while the sheet is not, and quality
hold exposes no writes at all. Those judgements live in the features; the foundation only provides the
verb.

## Role centre

The role centre belongs to the foundation and every activity on it belongs to the feature it is about.

Two rules were in tension. `CLAUDE.md` says Core carries no per-feature knowledge; a role centre
listing fourteen features' counts would be the largest violation of that rule in the app — and it is
the shape almost every BC app ends up with, because a cue page binds to a cue table and somebody has
to own the fields. `_patterns/role-center-cues.md` adds that counts must come from a **page background
task** against a **`TableType = Temporary`** table with **plain `Integer`** fields, never FlowFields,
so the home page opens instantly.

The resolution is the same enum mechanism as everything else:

- `WHA Activity Provider` is extensible; Core's only value is `WHANone` → `WHA No Activity Cues`.
- `WHA Activities Cue Calc` walks the ordinals, asks each provider for counts, and returns them with
  `Page.SetBackgroundTaskResult`.
- `WHA Warehouse Activities` enqueues the task and has an **empty** cuegroup.

A feature contributes four objects in its own folder: a `tableextension` adding its cue fields, an
`enumextension` registering itself, a codeunit that counts, and a `pageextension` that places the
fields **and declares its own `OnPageBackgroundTaskCompleted` trigger** to write the counts back.

**That last object is why there is no event here.** A page extension can carry its own background-task
trigger, so each feature writes its own counts and the foundation never learns a cue field number. An
`[IntegrationEvent]` publisher was written and then deleted once that was found — this app forbids
custom publishers, and the seam did not need one.

Feature toggles are respected twice: every cue field carries its feature's `ApplicationArea`, and every
count implementation's first line is the `IsEnabled` guard. A switched-off feature contributes
**nothing** rather than a zero, because a zero would be a claim about a warehouse that is not running
that feature.

`OnPageBackgroundTaskError` is swallowed. A failed count must never block somebody's home page.

### Who contributes

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

`WHA Foundation Tests` (codeunit 51015), 4 tests — all of them about the enum mechanism, because that
is what the foundation *is*:

- **Every feature answers whether it is switched on.** A feature ships by adding an enum value, and the
  failure that invites is a value with nothing bound to it. Walking every ordinal is what catches it,
  and nothing else in the app would notice until somebody opened the setup list.
- **Every activity provider answers without clashing.** All providers add counts to one dictionary, and
  `Dictionary.Add` throws on a duplicate key — so two features claiming the same cue field number would
  take the home page down. This test is where that surfaces, and it is the reason counts are keyed by
  `FieldNo` rather than by a string somebody chose.
- **Switching a feature on moves the enabled fingerprint**, which is what the setup pages compare to
  decide whether the session is owed a restart.
- **The `WHANone` value never reports itself as enabled**, so an unbound value fails safe.

Covered indirectly: every feature test that calls `ApplyChoices` or reads `IsEnabled` exercises the
dispatch, and `WHA Warehouse Task Tests` and `WHA Quality Hold Tests` assert the cue contract including
that a switched-off feature returns **no keys at all**.

The background task itself is not unit-tested: `Page.SetBackgroundTaskResult` needs a page session.

## Not done

- **Three claims in this document are still unchecked.** That the guided setup lists every feature
  exactly once, that the hub restarts the session exactly once, and that `RegisterMcpConfiguration` is
  genuinely idempotent across two runs. The first needs `WHA Guided Setup.PopulateSteps` to be
  reachable from the test app — it is `internal`, and widening an API to suit a test is the wrong
  trade to make quietly. The second is a session-level behaviour a unit test cannot observe. The third
  needs the platform's MCP tables in a state a test can assert on.
- **`WHA Warehouse Setup` is a table with one field.** It exists to mark that a step was run. Whether
  it should exist at all is worth asking the next time something needs to go on it.
- **The role centre has almost no navigation**, no headline, no charts and no targets — a tile is
  never red, because nothing knows what good looks like. That is the same gap `FEAT-KPI-001` records,
  now visible on a home page rather than buried in a document.
- **One role centre, and it is the manager's.** There is no operator profile; `FEAT-RF-001` is what an
  operator uses, and it has still never been seen by one.
- **No getting-started in the customer language** — the language has not been confirmed.
