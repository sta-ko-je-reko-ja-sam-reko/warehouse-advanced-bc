# FEAT-KPI-001 - Analytics

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Standard Business Central has warehouse reports and, since analysis views, plenty of ways to slice
> a ledger. What it has none of is a measure of how the *warehouse* is running, because the events
> that would answer it — a job finished, a pick that came up short, a lorry that waited an hour —
> are the events this app introduced. **This feature invents no data whatsoever.** It is the second
> feature after slotting and labour management that only reads what the app already recorded, and
> the last one in the catalogue for exactly that reason.

## Business process

1. Somebody opens the KPI screen, chooses a site and a period, and gets a handful of figures worked
   out on the spot.
2. When a period is worth keeping — a week, a month — the figures are **captured**, and a captured
   figure can be compared with the one before it.
3. That is the whole feature. Nothing is scheduled, nothing is judged against a target, and nothing
   is written anywhere else.

### Delivered so far

**Segment 1** — five measures behind a swappable interface, live figures, kept snapshots, comparison
with the previous period, and an aggregated throughput query.

## The five measures

Each is one `WHA IKpiMeasure` implementation. A measure reads, works out one number, and does
nothing else: it never writes, and it never asks another measure for anything, so measures can be
added and removed without disturbing each other. A dependent app adds one with an `enumextension` on
`WHA KPI Measure` — no object in this app changes, and the new measure appears on the screen, in the
capture and in the API by itself.

| Measure | Reads | Measured in | Better |
|---|---|---|---|
| **Jobs finished** | Completed warehouse tasks | jobs | higher |
| **Hours from raised to put away** | Completed put-away tasks | hours | lower |
| **Picks that came up short** | Completed pick tasks where less was moved than asked for | percent | lower |
| **Minutes a vehicle is on site** | Departed dock appointments | minutes | lower |
| **Minutes waiting for a door** | Dock appointments that reached a door | minutes | lower |

Three of them read `FEAT-TASK-001`, two read `FEAT-DOCK-001`. **A measure whose feature is switched
off returns zero rather than failing** — the tables exist either way, and an empty table is a real
answer to "how many jobs did you finish".

### Why there is no dock-to-stock

The catalogue asks for it by name, and it is the measure a warehouse manager would name first. It is
**not delivered, and it is not an oversight**: dock-to-stock is the clock from a vehicle arriving to
the goods being on the shelf, and *nothing in this app links a put-away to the vehicle that brought
the goods*. A booking carries a free-text reference; a put-away task carries an item and a bin. Any
number the app produced by pairing them on time-of-day would be a guess wearing a KPI's clothes.

What ships instead is honest about where its clock starts:

- **Hours from raised to put away** — the warehouse's half of dock-to-stock, measured from the
  moment the work existed.
- **Minutes a vehicle is on site** — the yard's half, measured gate to gate.

Closing the gap means giving `FEAT-DOCK-001` a link to what was on the vehicle. That is a scope
decision about the receiving process, not a reporting problem, which is why it is not being solved
in a KPI codeunit.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Analytics Setup` | 50700 | Single-record feature setup |
| `WHA KPI Snapshot` | 50701 | One figure, for one measure, one site and one period |

### `WHA KPI Snapshot`

A snapshot keeps `Value` **and** `Measured In`, the two dates it covers, and who took it. The unit is
stored rather than looked up so that an old snapshot still reads correctly if a measure is ever
redefined, and the period is stored because two figures are only worth comparing when they cover
periods of the same length.

`Location Code` blank means the whole company was measured as one.

**Capturing the same site, measure and period twice replaces the figure.** A period has one answer,
and two answers for the same period is a question about which one is right — somebody will pick the
flattering one.

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Analytics Setup` | table | 50700 | `app/src/Analytics/tables/AnalyticsSetup.Table.al` |
| `WHA KPI Snapshot` | table | 50701 | `app/src/Analytics/tables/KPISnapshot.Table.al` |
| `WHA KPI Measure` | enum | 50700 | `app/src/Analytics/enums/KPIMeasure.Enum.al` |
| `WHA IKpiMeasure` | interface | — | `app/src/Analytics/interfaces/IKpiMeasure.Interface.al` |
| `WHA IKpiSnapshot` | interface | — | `app/src/Analytics/interfaces/IKpiSnapshot.Interface.al` |
| `WHA KPI Mgt.` | codeunit | 50700 | `app/src/Analytics/codeunits/KPIMgt.Codeunit.al` |
| `WHA KPI Snapshot Logic` | codeunit | 50701 | `app/src/Analytics/codeunits/KPISnapshotLogic.Codeunit.al` |
| `WHA KPI Feature Setup` | codeunit | 50702 | `app/src/Analytics/codeunits/KPIFeatureSetup.Codeunit.al` |
| `WHA KPI App Area Sub.` | codeunit | 50703 | `app/src/Analytics/codeunits/KPIAppAreaSub.Codeunit.al` |
| `WHA Demo Analytics` | codeunit | 50704 | `app/src/Analytics/codeunits/DemoAnalytics.Codeunit.al` |
| `WHA KPI Tasks Completed` | codeunit | 50705 | `app/src/Analytics/codeunits/KPITasksCompleted.Codeunit.al` |
| `WHA KPI Put-away Lead` | codeunit | 50706 | `app/src/Analytics/codeunits/KPIPutawayLead.Codeunit.al` |
| `WHA KPI Pick Short Rate` | codeunit | 50707 | `app/src/Analytics/codeunits/KPIPickShortRate.Codeunit.al` |
| `WHA KPI Trailer Turnaround` | codeunit | 50708 | `app/src/Analytics/codeunits/KPITrailerTurnaround.Codeunit.al` |
| `WHA KPI Door Wait` | codeunit | 50709 | `app/src/Analytics/codeunits/KPIDoorWait.Codeunit.al` |
| `WHA KPI Scheduler` | codeunit | 50710 | `app/src/Analytics/codeunits/KPIScheduler.Codeunit.al` |
| `WHA Task Throughput` | query | 50700 | `app/src/Analytics/queries/TaskThroughput.Query.al` |
| `WHA KPI Appl. Area Setup` | tableextension | 50700 | `app/src/Analytics/tableextensions/KPIApplAreaSetup.TableExt.al` |
| `WHA Analytics Setup` | page | 50700 | `app/src/Analytics/pages/AnalyticsSetup.Page.al` |
| `WHA Warehouse KPIs` | page | 50701 | `app/src/Analytics/pages/WarehouseKPIs.Page.al` |
| `WHA KPI Snapshots` | page | 50702 | `app/src/Analytics/pages/KPISnapshots.Page.al` |
| `WHA API KPI Snapshot` | page | 50703 | `app/src/Analytics/pages/APIKPISnapshot.Page.al` |
| `WHA API Demo Analytics` | page | 50704 | `app/src/Analytics/pages/APIDemoAnalytics.Page.al` |
| `WHA Analytics Tests` | codeunit | 51013 | `test/src/codeunits/AnalyticsTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.Analytics`, from the reserved block `50700..50749`. Core gained a
`WHA Feature` enum value; nothing else outside the feature changed.

## Live figures and kept figures

`WHA Warehouse KPIs` is a worksheet over a **temporary** `WHA KPI Snapshot`: choosing a site or a
period works every measure out again on the spot and keeps nothing. Reading a figure changes
nothing, which is what makes the screen safe to put in front of anybody.

**Keep these figures** writes the same set to the table, and that is the only thing in the feature
that writes at all.

`WHA KPI Snapshots` colours a kept figure against the last one taken for the same measure and site.
The app has **no targets**, so it will not say a figure is good; the most it says is which way the
figure moved — and `WHA IKpiMeasure.HigherIsBetter` is the only reason it knows which way that is.

## The query

`WHA Task Throughput` is an API query, not a page: completed-task counts and quantities grouped by
location, task type and status, with a filter element on the completion time for callers in AL. It
is the feed for a spreadsheet or a Power BI report — the place a user goes when the five measures
are not the cut they wanted. It is deliberately **not** an MCP tool: an MCP tool is an API page, and
an agent asking for a shape of its own choosing is better served by the snapshot entity, which comes
with a unit and a period attached.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHAAnalytics` bound to
`WHA KPI Feature Setup` (guided setup step 150); `Application Area Setup` gained `WHA Analytics`
through this feature's own tableextension; the setup page is `ApplicationArea = All` while the KPI
pages carry `WHAAnalytics`.

**No new number series.**

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Analytics` | `analytics` | `WHA API KPI Snapshot` | **read only** |
| `Warehouse Advanced - Demo Analytics` | `demoAnalytics` | `WHA API Demo Analytics` | run `importDemoData` only |

An agent reads figures somebody kept and nothing else. It cannot capture, because capturing decides
which period the warehouse is going to be judged on, and it cannot work a figure out live, because
every live figure carries the period it was measured over and an agent quoting one without it would
be quoting a number with no meaning.

## Demo data

`WHA Demo Analytics` seeds **no records of its own**. It captures one set of figures over the period
the setup asks for. On a company that has run the other features' sample data there is something to
measure; on an empty one every figure is correctly zero. Running it again replaces the figures
rather than adding a second set. `Import()` builds the `WHA-KPI` RapidStart package.

## Tests

`WHA Analytics Tests` (codeunit 51013), 14 tests. Two cover the scheduled capture: it keeps the
period's figures, and it refuses when analytics is switched off. The other 12: jobs finished counts
only what was finished inside
the period; nothing to measure is zero rather than a failure; the short rate is the share of picks
that came up short and ignores put-aways; put-away lead time counts put-aways and nothing else;
turnaround is measured gate to gate; waiting for a door is measured apart from the visit; a vehicle
still on site has no turnaround yet but its wait is known; capturing keeps one figure per measure and
replaces it on a re-run; a kept figure remembers its unit, its period and who took it; which way is
better depends on the measure; a figure with nothing before it is not compared; and demo idempotency.

The elapsed part of **hours from raised to put away** is the one thing not asserted exactly: it is
measured from the platform's own created stamp, which a test cannot fabricate. The test asserts
which jobs the measure looks at instead.


## Scheduling is the job queue's, not ours

`WHA KPI Scheduler` is a `TableNo`-bound codeunit whose `OnRun` does the capture. A job queue entry points at it,
and Business Central decides when and how often — the entry's own `Location Code` filter narrows the
run.

The period comes from `Default Period Days` on the analytics setup: the run passes no dates and lets
`ResolveDates` fill them, so the schedule and the screen agree about what a period is without the
scheduler holding an opinion of its own.

**Nothing in this feature stores a recurrence.** BC already schedules, logs failures, retries and
handles time zones; a *run at 06:00 daily* field here would be a worse copy of one that already
exists. What the feature owns is *what* to run; *when* belongs to the platform.

The first line of the run is the same `CheckEnabled` guard every write path uses, so a job queue entry
left in place after somebody switches the feature off stops rather than quietly carrying on.

## Not done

- **No dock-to-stock**, for the reason above. This is the largest gap and it is a scope decision
  rather than a reporting one.
- **No targets.** Nothing says what good looks like, so nothing is ever red for being bad — only for
  moving the wrong way since last time.
- ~~**A missed run is a gap, not a catch-up.**~~ **Delivered.** `CaptureMissing` keeps today's
  figures and then fills in every day since the last capture, bounded by **Catch up over** in the
  setup. Three limits stayed, deliberately: a company that has never captured anything gets today and
  nothing else, because a first run should not invent a history nobody was there for; a day already
  captured is left alone unless it is today, because a finished day's figure does not change; and a
  filled-in day is worked out **now** from the records as they stand now, which is not what the run
  would have said on the day if anything has been edited since. Nothing can fix the third one, and
  saying so is the honest version of fixing the first two.
- **No labour measures.** `FEAT-LAB-001` already works out measured time against standards, and
  jobs-per-hour belongs here, but it would be the first measure to read a second app feature's
  derived figures rather than raw events.
- **No cues, though there is now a role centre to put them on.** `FEAT-CORE-001` ships one, and this
  feature deliberately contributes no tile to it: a cue is a count of *things that need a person
  today*, and a KPI is a reading of history. Whether a measure belongs on a home page as a figure
  rather than a count is a real question and it has not been answered — `_patterns/role-center-cues.md`
  is the pattern if it ever is.
- **No trend or chart anywhere.** Snapshots are a list; comparing more than two periods means
  exporting them.
- **Getting-started in the customer language** — the language has not been confirmed.
