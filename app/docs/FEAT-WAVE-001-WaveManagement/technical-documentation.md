# FEAT-WAVE-001 - Wave Management

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Waves are the first Wave C item and the first feature that reorganises work rather than adding a
> new kind of it — which makes it the one most likely to be wrong in a way nobody notices, because
> a badly-chosen wave still looks like a working wave.

## Business process

Standard Business Central releases warehouse work one document at a time. A warehouse that ships to
departures does not work that way: it wants everything for the four o'clock lorry to start together,
be worked together, and be finished together — so that a half-finished round is visible as a
half-finished round.

A **wave** is that batch:

1. A wave is opened for a location, with a **strategy** — how it decides which work belongs to it —
   and a cap on how many jobs it takes.
2. It is **filled**. The strategy narrows and orders the outstanding work; the wave takes as many as
   its cap allows.
3. Work can be added or taken out by hand while the wave is open.
4. It is **released**: every job in it goes to the floor at once.
5. It is **completed** when all of its work is finished or withdrawn.

A wave that is no longer wanted is **cancelled**, which withdraws the jobs in it that nobody has
started.

### Delivered so far

**Segment 1** — the wave entity, two strategies, filling, releasing, completion and cancellation.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Wave Setup` | 50150 | Single-record feature setup |
| `WHA Wave` | 50151 | One batch of work |

### `WHA Wave`

| Field | Type | Notes |
|---|---|---|
| `No.` | `Code[20]` | Primary key, from the foundation number series |
| `Description` | `Text[100]` | The shift or departure this wave is for |
| `Location Code` | `Code[10]` | The part of the warehouse it gathers from. **Required before filling** |
| `Status` | `Enum "WHA Wave Status"` | Open / Released / Completed / Cancelled. Not editable |
| `Strategy` | `Enum "WHA Wave Strategy"` | How it decides what belongs to it |
| `Max Tasks` | `Integer` | How many jobs it takes when filled. Zero uses the setup default |
| `Released At` / `Completed At` | `DateTime` | Stamped by the life cycle |
| `Task Count` / `Completed Task Count` | `Integer` | FlowFields over the tasks pointing at this wave |

**Membership lives on the task, not on the wave.** `WHA Warehouse Task` gained `Wave No.` and a
`Wave` key. That is a deliberate coupling in one direction: **wave management writes that field and
directed work never reads it.** The alternative — a link table — would have put a join in front of
every queue read for a feature the customer may not even use.

`Completed Task Count` counts **cancelled** jobs as well as completed ones, because the question it
answers is "what is still outstanding", and a withdrawn job is not.

### `WHA Wave Setup`

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Default Strategy` | What a new wave uses unless it says otherwise |
| `Default Max Tasks` | Ships as 25. A wave bigger than a shift can finish is a wave nobody trusts |
| `Include Unreleased Work` | Whether a wave may gather **drafts** and release them with the wave — see below |

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Wave Setup` | table | 50150 | `app/src/WaveManagement/tables/WaveSetup.Table.al` |
| `WHA Wave` | table | 50151 | `app/src/WaveManagement/tables/Wave.Table.al` |
| `WHA Wave Status` | enum | 50150 | `app/src/WaveManagement/enums/WaveStatus.Enum.al` |
| `WHA Wave Strategy` | enum | 50151 | `app/src/WaveManagement/enums/WaveStrategy.Enum.al` |
| `WHA IWave` | interface | — | `app/src/WaveManagement/interfaces/IWave.Interface.al` |
| `WHA IWaveStrategy` | interface | — | `app/src/WaveManagement/interfaces/IWaveStrategy.Interface.al` |
| `WHA Wave Logic` | codeunit | 50150 | `app/src/WaveManagement/codeunits/WaveLogic.Codeunit.al` |
| `WHA Wave Feature Setup` | codeunit | 50151 | `app/src/WaveManagement/codeunits/WaveFeatureSetup.Codeunit.al` |
| `WHA Wave App Area Sub.` | codeunit | 50152 | `app/src/WaveManagement/codeunits/WaveAppAreaSub.Codeunit.al` |
| `WHA Demo Wave` | codeunit | 50153 | `app/src/WaveManagement/codeunits/DemoWave.Codeunit.al` |
| `WHA Wave Default Strategy` | codeunit | 50154 | `app/src/WaveManagement/codeunits/WaveDefaultStrategy.Codeunit.al` |
| `WHA Wave Due Strategy` | codeunit | 50155 | `app/src/WaveManagement/codeunits/WaveDueStrategy.Codeunit.al` |
| `WHA Wave Strategy Filters` | codeunit | 50156 | `app/src/WaveManagement/codeunits/WaveStrategyFilters.Codeunit.al` |
| `WHA Wave Appl. Area Setup` | tableextension | 50150 | `app/src/WaveManagement/tableextensions/WaveApplAreaSetup.TableExt.al` |
| `WHA Wave Setup` | page | 50150 | `app/src/WaveManagement/pages/WaveSetup.Page.al` |
| `WHA Waves` | page | 50151 | `app/src/WaveManagement/pages/Waves.Page.al` |
| `WHA Wave Card` | page | 50152 | `app/src/WaveManagement/pages/WaveCard.Page.al` |
| `WHA API Wave` | page | 50153 | `app/src/WaveManagement/pages/APIWave.Page.al` |
| `WHA API Demo Wave` | page | 50154 | `app/src/WaveManagement/pages/APIDemoWave.Page.al` |
| `WHA Wave Tests` | codeunit | 51004 | `test/src/codeunits/WaveTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.WaveManagement`, from the reserved block `50150..50199`.
Directed work gained `Wave No.` and two keys; foundation gained the `Wave Nos.` series; Core gained
a `WHA Feature` enum value.

## Strategies — a filter and a sort, nothing else

`WHA IWaveStrategy` has two methods:

| Method | Meaning |
|---|---|
| `SelectCandidates` | Narrow and order the task record you are given; answer whether anything matched |
| `Describe` | One line saying what you pick, shown on the wave card before the user fills it |

**A strategy never loops.** It applies filters and a sort; `WHA Wave Logic` finds and walks the
records and stops at the cap. That is not a style preference — a strategy that consumed the set it
was asked to describe, or that forgot to exclude work already in a wave, would quietly steal jobs
off the floor. `WHA Wave Strategy Filters` holds the exclusions every strategy must have (not
already in a wave, at this location, not already in somebody's hands), so a new strategy cannot
forget them.

Two ship:

- **Most urgent first** (default) — priority, then due date. The same order the queue itself hands
  work out in, so a wave built this way is *the work that would have been done next anyway*,
  gathered so it goes out together.
- **Due first** — due date only, whatever the priority. For a warehouse that ships to departure
  times, where what leaves at four o'clock matters more than what somebody marked urgent.

`WHA Wave Strategy` is extensible, so a third — by carrier, by zone, by customer, balanced across
operators — is an `enumextension` value and one codeunit.

## Draft work, and who approves it

`Include Unreleased Work` decides whether filling a wave may pick up tasks that are still drafts:

- **Off (default):** a wave gathers only work already approved for the floor. Releasing the wave
  changes *when* that work becomes visible, never *whether* it was approved.
- **On:** the wave is the approval. Drafts are gathered, and releasing the wave releases them.

The default is off because sweeping unapproved work into a batch and putting it on the floor is a
decision somebody should make deliberately, once, in setup — rather than discovering it the first
time a wave goes out.

## Completion is asked for, not pushed

Nothing in directed work tells a wave that one of its jobs finished. That would mean the task logic
knowing about waves, and this app's rule is that features do not reach sideways into each other.

So a wave is closed by **asking**: `CompleteIfFinished` closes a released wave whose work is all
done, and does nothing to one that is not. It is called from **Close finished waves** on the wave
list, and is safe to run from a job queue.

The consequence, stated plainly: **a wave's status can lag behind reality.** `Task Count` and
`Completed Task Count` are FlowFields and are always current, so the list shows the truth about the
*work* even when the wave's own status has not caught up.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHAWaveManagement` bound to
`WHA Wave Feature Setup` (guided setup step 60); `Application Area Setup` gained
`WHA Wave Management` through this feature's own tableextension; the app-area subscriber sets it
from `Enabled`; the setup page is `ApplicationArea = All` while the wave pages carry
`WHAWaveManagement`. Every API write path and bound action calls `CheckEnabled`.

**The foundation now creates three number series** (`WHA-HU`, `WHA-TASK`, `WHA-WAVE`) and
`IsComplete` checks all three, so a company that ran the foundation step before this feature shipped
shows it as *not started* again until it is re-run. Re-running is idempotent.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Wave Management` | `waveManagement` | `WHA API Wave` | read, create, modify, and run fill / release / complete / cancel — **not delete** |
| `Warehouse Advanced - Demo Wave Management` | `demoWaveManagement` | `WHA API Demo Wave` | run `importDemoData` only |

Unlike the handheld, an agent **may** release a wave: that is a planning decision made at a desk
from information the agent can see, not a claim about where somebody was standing.

## Demo data

`WHA Demo Wave` seeds three waves under fixed numbers `DEMO-WAVE-001..003`: one open and filled, one
filled and released, and one created but never used. It gathers from a location that already has
released work, so the sample waves are not empty on a company that has run the directed work sample
data first. `Import()` also builds the `WHA-WAVE` RapidStart package.

## Tests

`WHA Wave Tests` (codeunit 51004), 17 tests: filling takes the most urgent work first and stops at
the cap; work at other locations, drafts, and work already in a wave are left alone; drafts are
gathered and released when the setup allows it; an empty wave cannot be released; a released wave
cannot be changed or deleted; taking work out of a wave leaves the job itself alone; a wave with
work outstanding cannot be completed but closes when its work is done; cancelling withdraws
unstarted work; deleting an open wave frees its work; the due-first strategy takes different work
from the default; and demo idempotency.

## Not done

- **Wave templates.** The catalogue names them. A wave is created by hand each time — there is no
  "every morning, this location, this strategy, this cap" definition, and no scheduling.
- **Workload balancing.** Also in the catalogue, also absent. Nothing spreads a wave's work across
  operators or estimates whether a wave is a shift's worth of work; `Max Tasks` is a count, and a
  count is a poor proxy for effort.
- **Automatic completion.** See above — deliberate, but it means the list needs running or a job
  queue entry to stay honest.
- **No wave on the handheld.** An operator is handed work by the queue and never sees which wave it
  came from. Whether they should is an operator-review question.
- **Getting-started in the customer language** — the language has not been confirmed.
