# FEAT-LAB-001 - Labour Management

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Standard Business Central has nothing here at all, so unlike replenishment or counting there is no
> risk of rebuilding something that already exists. The risk is the opposite one: measuring people is
> easy to build and hard to do well, and whether this customer wants it measured is a question for
> Phase 0 and for whoever runs the floor — not for the app.

## Business process

The task queue has been recording who held every job, when they started it and when they finished it
since `FEAT-TASK-001` shipped. **Nothing has ever read those four fields.** This feature reads them.

1. A **standard** says how long a kind of job should take: an allowance for the job itself, and an
   allowance per unit handled.
2. Finished warehouse work is **turned into recorded time** — one entry per job, with what it
   actually took and what the standard expected.
3. Time that was *not* spent on a job — breaks, cleaning, waiting for work, an equipment failure — is
   **recorded too**, because a warehouse where only the picking is measured looks more productive
   than it is.

### Delivered so far

**Segment 1** — standards, two bases, generation of time from finished work, and indirect time.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Labour Setup` | 50350 | Single-record feature setup |
| `WHA Labour Standard` | 50351 | How long a kind of job should take |
| `WHA Labour Entry` | 50352 | One piece of recorded time |

### `WHA Labour Standard`

Keyed by **location and task type**, so a site with longer aisles can have its own numbers. A
standard written for a blank location applies everywhere one has not been written; the lookup takes
the specific one first and falls back to the general one.

| Field | Notes |
|---|---|
| `Location Code`, `Task Type` | The primary key |
| `Basis` | How the expected time is worked out |
| `Minutes Per Job` | The walking, the scanning and the paperwork, which happen once |
| `Minutes Per Unit` | What each unit handled adds |
| `Blocked` | Ignored, so work is recorded with **no** expected time rather than against a number nobody trusts |

### `WHA Labour Entry`

| Field | Notes |
|---|---|
| `Entry No.` | `AutoIncrement`. Recorded time is an event, like a packing session or a hold |
| `Entry Type` | On a job, or not on a job |
| `User ID`, `Location Code`, `Posting Date` | Whose time, where, and which day |
| `Task No.`, `Task Type`, `Quantity Handled` | The job it came from. Blank on time that was not on a job |
| `Indirect Reason`, `Description` | What the time was for |
| `Started At`, `Ended At`, `Actual Minutes` | How long it took |
| `Expected Minutes`, `Performance Percent` | What the standard said, and the one against the other |
| `Measured Against Standard` | Whether anything measured it at all |

**`Performance Percent` is expected over actual.** A hundred is exactly to standard and more than a
hundred is faster than standard, which is the way round every warehouse states it.

The `Person` and `Placement` keys carry `SumIndexFields` on both minute columns, so totals per person
per day and per location per day are a `CalcSums` rather than a scan.

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Labour Setup` | table | 50350 | `app/src/LabourManagement/tables/LabourSetup.Table.al` |
| `WHA Labour Standard` | table | 50351 | `app/src/LabourManagement/tables/LabourStandard.Table.al` |
| `WHA Labour Entry` | table | 50352 | `app/src/LabourManagement/tables/LabourEntry.Table.al` |
| `WHA Labour Entry Type` | enum | 50350 | `app/src/LabourManagement/enums/LabourEntryType.Enum.al` |
| `WHA Indirect Reason` | enum | 50351 | `app/src/LabourManagement/enums/IndirectReason.Enum.al` |
| `WHA Labour Standard Basis` | enum | 50352 | `app/src/LabourManagement/enums/LabourStandardBasis.Enum.al` |
| `WHA ILabourStandard` | interface | — | `app/src/LabourManagement/interfaces/ILabourStandard.Interface.al` |
| `WHA ILabourStandardRule` | interface | — | `app/src/LabourManagement/interfaces/ILabourStandardRule.Interface.al` |
| `WHA ILabourEntry` | interface | — | `app/src/LabourManagement/interfaces/ILabourEntry.Interface.al` |
| `WHA Labour Std. Logic` | codeunit | 50350 | `app/src/LabourManagement/codeunits/LabourStdLogic.Codeunit.al` |
| `WHA Labour Entry Logic` | codeunit | 50351 | `app/src/LabourManagement/codeunits/LabourEntryLogic.Codeunit.al` |
| `WHA Labour Mgt.` | codeunit | 50352 | `app/src/LabourManagement/codeunits/LabourMgt.Codeunit.al` |
| `WHA Lab. Feature Setup` | codeunit | 50353 | `app/src/LabourManagement/codeunits/LabFeatureSetup.Codeunit.al` |
| `WHA Lab. App Area Sub.` | codeunit | 50354 | `app/src/LabourManagement/codeunits/LabAppAreaSub.Codeunit.al` |
| `WHA Demo Labour` | codeunit | 50355 | `app/src/LabourManagement/codeunits/DemoLabour.Codeunit.al` |
| `WHA Std. Fixed Plus Unit` | codeunit | 50356 | `app/src/LabourManagement/codeunits/StdFixedPlusUnit.Codeunit.al` |
| `WHA Std. Fixed Only` | codeunit | 50357 | `app/src/LabourManagement/codeunits/StdFixedOnly.Codeunit.al` |
| `WHA Lab. Appl. Area Setup` | tableextension | 50350 | `app/src/LabourManagement/tableextensions/LabApplAreaSetup.TableExt.al` |
| `WHA Labour Setup` | page | 50350 | `app/src/LabourManagement/pages/LabourSetup.Page.al` |
| `WHA Labour Standards` | page | 50351 | `app/src/LabourManagement/pages/LabourStandards.Page.al` |
| `WHA Labour Entries` | page | 50352 | `app/src/LabourManagement/pages/LabourEntries.Page.al` |
| `WHA API Labour Entry` | page | 50353 | `app/src/LabourManagement/pages/APILabourEntry.Page.al` |
| `WHA API Labour Standard` | page | 50354 | `app/src/LabourManagement/pages/APILabourStandard.Page.al` |
| `WHA API Demo Labour` | page | 50355 | `app/src/LabourManagement/pages/APIDemoLabour.Page.al` |
| `WHA Labour Tests` | codeunit | 51010 | `test/src/codeunits/LabourTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.LabourManagement`, from the reserved block `50350..50399`. Core
gained a `WHA Feature` enum value; **nothing else outside the feature changed, and nothing in
directed work knows this exists**.

## Bases — reading a standard, and nothing else

`WHA ILabourStandard` answers one question: given this standard and this quantity, how many minutes
should it have taken. **A basis never looks at how long the work actually took**, so it cannot be
written — or later edited — to agree with the answer.

| Basis | What it uses |
|---|---|
| **Per job plus per unit** (default) | The job allowance plus the per-unit allowance. The ordinary shape of an engineered standard: the walk happens once, the picking happens per unit |
| **Per job only** | The job allowance, whatever was handled. Right where the quantity is not what takes the time — moving one whole pallet takes as long whether it holds ten cases or a hundred |

The enum is extensible, so a basis that varies by travel distance, by unit of measure, or by a
learning curve for new starters is one value and one codeunit.

## Generation is asked for, not pushed

Nothing in directed work tells labour management that a job finished. That would mean the task queue
knowing about a feature the customer may not have bought, and this app's rule is that features do not
reach sideways into each other.

So entries are **generated by asking**: `Generate` walks completed work in a date range and creates
one entry per job that does not already have one. It is safe to run repeatedly and safe to schedule.
The guard is the `Task` key on the entry, so a job counted once is never counted twice.

Work is skipped, rather than recorded wrong, when:

- **nobody held it** — a completed job with no assigned user is a gap in the record, not somebody's
  hour;
- **it has no start** — a job that was never properly started has no measurable duration.

## The believability guard

`Longest believable job` (ships at 240 minutes) is the answer to somebody starting a job and going
home. Time longer than that is **still recorded** — it happened, and hiding it would hide the process
problem — but it is marked as not measured, so it does not drag a whole shift's performance figures
down. Set it to zero to believe everything.

## Personal data

`User ID` on both the entry and its task is `EndUserIdentifiableInformation`. This feature produces
**per-person performance figures**, which is the most sensitive data the app has ever held.

Two consequences, both deliberate:

- The **entry API is read-only**, and its MCP tool is read-only as well. Nothing may write somebody's
  hours through an agent.
- The agent instructions tell the agent to answer questions about *the warehouse* — where the hours
  go, which kinds of work are furthest from standard, how much time is not on a job — and not to rank
  named individuals. That is guidance, not enforcement; the data is there for anybody with permission
  to the table.

Before this ships to a customer, somebody has to decide whether per-person measurement is wanted at
all, and say so to the people being measured. That is not a technical question and the app does not
answer it.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHALabourManagement` bound to
`WHA Lab. Feature Setup` (guided setup step 120); `Application Area Setup` gained
`WHA Labour Management` through this feature's own tableextension; the setup page is
`ApplicationArea = All` while the labour pages carry `WHALabourManagement`.

**No new number series.** Recorded time is an event, numbered by the platform.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Labour Management` | `labourManagement` | `WHA API Labour Standard` | read, create and modify |
| `Warehouse Advanced - Labour Management` | `labourManagement` | `WHA API Labour Entry` | **read only** |
| `Warehouse Advanced - Demo Labour Management` | `demoLabourManagement` | `WHA API Demo Labour` | run `importDemoData` only |

Standards are writable because they are a statement about the work, not about a person. Entries are
not, because they are about a person.

## Demo data

`WHA Demo Labour` seeds four standards — three on the per-job-plus-per-unit basis and one per-job-only
— then runs `Generate` over whatever finished work the company has and records one break so the two
kinds of time can be told apart. On a company that has run the directed work sample data, that
produces real measured entries; on an empty one it produces the standards and nothing else, which is
correct rather than a failure. `Import()` also builds the `WHA-LAB` RapidStart package.

## Tests

`WHA Labour Tests` (codeunit 51010), 13 tests: finished work becomes recorded time with the right
minutes and the right person; the same job is never counted twice; work nobody held is not recorded; a
standard of two minutes plus half a minute a unit makes ten units a seven-minute job and fourteen
minutes half the expected pace; a standard written for a location beats the general one; the
per-job-only basis ignores what was handled; a blocked standard records the time but measures nothing;
a job too long to believe is recorded but not measured; time with no job is recorded as time off the
jobs; indirect time needs a person and some minutes; a standard of no time at all is refused; a run
only takes work from the location it was given; and demo idempotency.

## Not done

- **No shift or roster.** The app knows what somebody did, not when they were supposed to be there.
  Utilisation — measured time against paid time — needs a shift pattern nobody has supplied, so what
  ships answers *how fast* rather than *how busy*.
- **No cost.** Minutes are minutes; nothing multiplies them by a rate.
- **Indirect time is typed in.** There is no clock-on for a break and nothing on the handheld, so
  indirect time is only as complete as somebody's diligence — and the incomplete case makes the
  warehouse look **better** than it is, which is the direction that misleads.
- **Nothing schedules the generation.** A job queue entry has to be created by an administrator.
- **No standards by item or by zone.** A standard is per task type and location. Picking a pallet of
  bricks and a box of envelopes are the same job to this feature.
- **Getting-started in the customer language** — the language has not been confirmed.
