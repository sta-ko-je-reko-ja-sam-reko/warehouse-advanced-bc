# FEAT-REPL-001 - Replenishment

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Replenishment is the first Wave D item. Standard Business Central already replenishes bins through
> the movement worksheet, so more of this feature than usual is at risk of being *configuration*
> rather than *gap* — that is the first thing Phase 0 should settle for it.

## Business process

A pick face runs out. Somebody notices, walks to the bulk bin, and brings a pallet — usually while
an order is waiting. A WMS notices first.

A **replenishment rule** says how a bin is kept stocked:

1. A rule names a location, a bin, an item, and how full that bin should be kept: a **minimum** it
   may run down to and a **maximum** it is filled back up to.
2. A **run** measures each rule's bin, using the rule's **method**.
3. A bin below its minimum gets a warehouse task raised for the difference between what is there and
   the maximum — fetched from the rule's source bin, or from wherever the operator finds it.
4. The task goes to the floor immediately, or waits as a draft, depending on the setup.

The run is safe to repeat and safe to schedule, which is the whole point: **a bin that already has
outstanding replenishment work is left alone**, so a run every ten minutes does not send ten people
to the same bin.

### Delivered so far

**Segment 1** — the rule, two measurement methods, the run, the duplicate guard, and the work it
raises.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Repl. Setup` | 50250 | Single-record feature setup |
| `WHA Replenishment Rule` | 50251 | One bin kept stocked |

### `WHA Replenishment Rule`

| Field | Type | Notes |
|---|---|---|
| `Location Code`, `Item No.`, `Variant Code`, `Bin Code` | | **The primary key.** A rule is identified by the bin it looks after, not by a number |
| `Description` | `Text[100]` | What the rule is for |
| `Unit of Measure Code` | `Code[10]` | Copied from the item when the item is chosen |
| `Minimum Quantity` | `Decimal` | How low the bin may run. **Zero never asks for anything** |
| `Maximum Quantity` | `Decimal` | How full it is filled back to. Zero makes the rule inert |
| `Method` | `Enum "WHA Repl. Method"` | How the bin is measured |
| `Source Bin Code` | `Code[20]` | Where the goods are fetched from. Blank leaves it to the operator |
| `Priority` | `Integer` | Priority of the work raised. Zero uses the setup default |
| `Blocked` | `Boolean` | Skipped by a run, without losing what the rule says |
| `Last Checked At` / `Last Task No.` | | Stamped by every run, whether or not it raised anything |

**There is no number series.** The natural key is what a rule *is*: one bin, one item. That also
makes a duplicate rule impossible to enter, which a numbered rule would not.

### `WHA Repl. Setup`

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Default Method` | What a new rule measures with unless it says otherwise |
| `Default Priority` | Priority of raised work. Ships as 20 — more urgent than routine work, less than a short pick |
| `Send replenishment work to the floor` | Ships **on**. Off leaves each run's proposals as drafts |

**The setup defaults are applied on insert, and win.** A rule inserted with `Method` at its first value
(`WHABinContent`) takes the setup's default method instead, so a rule that deliberately wants bin
content while the setup says handling units has to be changed after it is created. The same shape as
`Strategy` on a wave; the field stays editable.

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Repl. Setup` | table | 50250 | `app/src/Replenishment/tables/ReplSetup.Table.al` |
| `WHA Replenishment Rule` | table | 50251 | `app/src/Replenishment/tables/ReplenishmentRule.Table.al` |
| `WHA Repl. Method` | enum | 50250 | `app/src/Replenishment/enums/ReplMethod.Enum.al` |
| `WHA IReplenishment` | interface | — | `app/src/Replenishment/interfaces/IReplenishment.Interface.al` |
| `WHA IReplMethod` | interface | — | `app/src/Replenishment/interfaces/IReplMethod.Interface.al` |
| `WHA Repl. Rule Logic` | codeunit | 50250 | `app/src/Replenishment/codeunits/ReplRuleLogic.Codeunit.al` |
| `WHA Repl. Feature Setup` | codeunit | 50251 | `app/src/Replenishment/codeunits/ReplFeatureSetup.Codeunit.al` |
| `WHA Repl. App Area Sub.` | codeunit | 50252 | `app/src/Replenishment/codeunits/ReplAppAreaSub.Codeunit.al` |
| `WHA Demo Replenishment` | codeunit | 50253 | `app/src/Replenishment/codeunits/DemoReplenishment.Codeunit.al` |
| `WHA Repl. Bin Content` | codeunit | 50254 | `app/src/Replenishment/codeunits/ReplBinContent.Codeunit.al` |
| `WHA Repl. Handling Units` | codeunit | 50255 | `app/src/Replenishment/codeunits/ReplHandlingUnits.Codeunit.al` |
| `WHA Replenishment Mgt.` | codeunit | 50256 | `app/src/Replenishment/codeunits/ReplenishmentMgt.Codeunit.al` |
| `WHA Repl. Appl. Area Setup` | tableextension | 50250 | `app/src/Replenishment/tableextensions/ReplApplAreaSetup.TableExt.al` |
| `WHA Repl. Setup` | page | 50250 | `app/src/Replenishment/pages/ReplSetup.Page.al` |
| `WHA Replenishment Rules` | page | 50251 | `app/src/Replenishment/pages/ReplenishmentRules.Page.al` |
| `WHA Repl. Rule Card` | page | 50252 | `app/src/Replenishment/pages/ReplRuleCard.Page.al` |
| `WHA API Repl. Rule` | page | 50253 | `app/src/Replenishment/pages/APIReplRule.Page.al` |
| `WHA API Demo Repl.` | page | 50254 | `app/src/Replenishment/pages/APIDemoRepl.Page.al` |
| `WHA Replenishment Tests` | codeunit | 51007 | `test/src/codeunits/ReplenishmentTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.Replenishment`, from the reserved block `50250..50299`. Core
gained a `WHA Feature` enum value; nothing else outside the feature changed.

## Methods — where the number comes from

`WHA IReplMethod` has two procedures: `Measure`, which answers what is in the bin, and `Describe`,
which says in one line where that number came from. **A method reads and nothing else** — it never
decides whether the level is too low and never raises work. That belongs to `WHA Replenishment Mgt.`,
so a new method cannot get the min/max arithmetic or the duplicate guard wrong.

Two ship:

- **Bin content** (default) — what standard Business Central believes is in the bin. A warehouse
  that posts its movements should use this and no other.
- **Handling units** — what the units standing in the bin say they hold. For a warehouse whose stock
  moves as licence plates, this is the number the floor would give you if you asked, and it can differ
  from bin content until the movements are posted.

That the two can disagree is not a defect to be designed away; it is the difference between what the
system has been told and what is on the floor, and a warehouse mid-cutover lives in that gap.

`WHA Repl. Method` is extensible, so a third — demand-driven from open picks, wave-aware
pre-replenishment — is an `enumextension` value and one codeunit.

## The duplicate guard

Before raising anything, the run looks for a replenishment task for the same location, bin, item and
variant that is neither completed nor cancelled. If one exists, the rule is stamped as checked and
nothing is raised.

This is what makes the run schedulable, and it is deliberately *outstanding work*, not *work that
ever existed*: a cancelled job leaves the bin free to ask again.

## What a run does not do

- **It does not move stock.** The run raises a warehouse task; the movement happens when an operator
  completes it, exactly as with any other directed work.
- **It does not check that the source bin has anything in it.** A rule pointing at an empty bulk bin
  raises work an operator cannot do. They report it short, which is what the short-pick path in
  `FEAT-TASK-001` exists for.
- **It does not run itself.** Nothing schedules it; **Replenish now** on the rule list, the API
  action, or a job queue entry does.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHAReplenishment` bound to
`WHA Repl. Feature Setup` (guided setup step 90); `Application Area Setup` gained `WHA Replenishment`
through this feature's own tableextension; the app-area subscriber sets it from `Enabled`; the setup
page is `ApplicationArea = All` while the rule pages carry `WHAReplenishment`. Every API write path
and bound action calls `CheckEnabled`.

Directed work has to be enabled as well — replenishment raises warehouse tasks, and a raised task
nobody can see is worse than no replenishment at all.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Replenishment` | `replenishment` | `WHA API Repl. Rule` | read, create, modify, and run `replenish` — **not delete** |
| `Warehouse Advanced - Demo Replenishment` | `demoReplenishment` | `WHA API Demo Repl.` | run `importDemoData` only |

## Demo data

`WHA Demo Replenishment` seeds three rules on the first location that has bins: a pick face measured
from bin content and topped up from a bulk bin, a second bin measured from the handling units standing
in it, and a blocked rule. It picks the first three bins at that location and the first unblocked item,
so it seeds nothing at all rather than something wrong on a company with no bins or no items.
`Import()` also builds the `WHA-REPL` RapidStart package.

## Tests

`WHA Replenishment Tests` (codeunit 51007), 12 tests: a bin below its minimum asks for enough to fill
it to the maximum, with the right bins, type and quantity; a bin with enough asks for nothing; the same
bin is not asked for twice, and withdrawn work lets it ask again; a blocked rule is skipped by a run and
says why when asked directly; a run only looks at the location it was given; stock on a unit in the bulk
bin is not counted as pick-face stock; a minimum above the maximum is refused; raised work goes to the
floor or stays a draft according to the setup; a run stamps when it looked even when it raised nothing;
and demo idempotency.

The tests use the **handling unit** method throughout, because it measures this app's own data. The
**bin content** method needs posted warehouse entries and belongs in the integration test plan; it is
not covered by an automated test yet, and that is a known hole rather than an oversight.

## Not done

- **Demand-driven replenishment.** The catalogue names it. Nothing looks at open picks or a released
  wave and pre-replenishes for them; every rule is min/max against a level measured now.
- **Wave-aware pre-replenishment.** Also named, also absent, and it is the more valuable half: filling
  the pick faces a wave is *about to* need is what stops the wave stalling halfway through.
- **No check on the source bin.** See above.
- **Nothing schedules the run.** A job queue entry has to be created by an administrator.
- **No unit of measure conversion.** The minimum, the maximum and the measurement are all assumed to
  be in the rule's unit. A rule in pallets over a bin content in pieces will be wrong, and nothing
  currently says so.
- **Getting-started in the customer language** — the language has not been confirmed.
