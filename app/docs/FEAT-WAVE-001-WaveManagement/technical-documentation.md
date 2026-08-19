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
**Segment 2** — templates and workload: a reusable definition that builds the same wave again
tomorrow, a scheduled run for a job queue to call, and a cap measured in **minutes of work** rather
than in a count of jobs.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Wave Setup` | 50150 | Single-record feature setup |
| `WHA Wave` | 50151 | One batch of work |
| `WHA Wave Template` | 50152 | A reusable definition of a wave, and the thing a schedule runs |

### `WHA Wave`

| Field | Type | Notes |
|---|---|---|
| `No.` | `Code[20]` | Primary key, from this feature's own number series |
| `Description` | `Text[100]` | The shift or departure this wave is for |
| `Location Code` | `Code[10]` | The part of the warehouse it gathers from. **Required before filling** |
| `Status` | `Enum "WHA Wave Status"` | Open / Released / Completed / Cancelled. Not editable |
| `Strategy` | `Enum "WHA Wave Strategy"` | How it decides what belongs to it |
| `Max Tasks` | `Integer` | How many jobs it takes when filled. Zero uses the setup default |
| `Max Minutes` | `Decimal` | How much **work** it takes when filled, from the labour standards. Zero uses the setup default |
| `Template Code` | `Code[20]` | The template that built it. Empty on a wave somebody created by hand |
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
| `Default Max Minutes` | Ships as zero, which means the job count is the only limit |
| `Include Unreleased Work` | Whether a wave may gather **drafts** and release them with the wave — see below |

### `WHA Wave Template`

| Field | Notes |
|---|---|
| `Code`, `Description` | What the template is, and how every wave it builds is described |
| `Location Code` | Required. A template covers one location, like the waves it builds |
| `Strategy`, `Max Tasks`, `Max Minutes` | Copied onto every wave it builds |
| `Release Automatically` | Whether the wave reaches the floor without anybody pressing anything |
| `Scheduled` | Whether the scheduled run includes it |
| `Blocked` | Out of use. A template finished with is blocked, never deleted |
| `Last Run At`, `Last Wave No.` | What happened last time. `Last Wave No.` stays empty when a run found nothing |
| `Wave Count` | FlowField over the waves that name it |

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
| `WHA Wave Template` | table | 50152 | `app/src/WaveManagement/tables/WaveTemplate.Table.al` |
| `WHA IWaveTemplate` | interface | — | `app/src/WaveManagement/interfaces/IWaveTemplate.Interface.al` |
| `WHA Wave Template Logic` | codeunit | 50157 | `app/src/WaveManagement/codeunits/WaveTemplateLogic.Codeunit.al` |
| `WHA Wave Scheduler` | codeunit | 50158 | `app/src/WaveManagement/codeunits/WaveScheduler.Codeunit.al` |
| `WHA Wave Templates` | page | 50155 | `app/src/WaveManagement/pages/WaveTemplates.Page.al` |
| `WHA Wave Template Card` | page | 50156 | `app/src/WaveManagement/pages/WaveTemplateCard.Page.al` |
| `WHA API Wave Template` | page | 50157 | `app/src/WaveManagement/pages/APIWaveTemplate.Page.al` |
| `WHA Wave Appl. Area Setup` | tableextension | 50150 | `app/src/WaveManagement/tableextensions/WaveApplAreaSetup.TableExt.al` |
| `WHA Wave Setup` | page | 50150 | `app/src/WaveManagement/pages/WaveSetup.Page.al` |
| `WHA Waves` | page | 50151 | `app/src/WaveManagement/pages/Waves.Page.al` |
| `WHA Wave Card` | page | 50152 | `app/src/WaveManagement/pages/WaveCard.Page.al` |
| `WHA API Wave` | page | 50153 | `app/src/WaveManagement/pages/APIWave.Page.al` |
| `WHA API Demo Wave` | page | 50154 | `app/src/WaveManagement/pages/APIDemoWave.Page.al` |
| `WHA Wave Tests` | codeunit | 51004 | `test/src/codeunits/WaveTests.Codeunit.al` |
| `WHA Wave Activities Cue` | tableextension | 50151 | `app/src/WaveManagement/tableextensions/WaveActivitiesCue.TableExt.al` |
| `WHA Wave Activity Provider` | enumextension | 50151 | `app/src/WaveManagement/enumextensions/WaveActivityProvider.EnumExt.al` |
| `WHA Wave Activity Cues` | codeunit | 50159 | `app/src/WaveManagement/codeunits/WaveActivityCues.Codeunit.al` |
| `WHA Wave Activities` | pageextension | 50151 | `app/src/WaveManagement/pageextensions/WaveActivities.PageExt.al` |

All in namespace `WarehouseAdvanced.WaveManagement`, from the reserved block `50150..50199`.
Directed work gained `Wave No.` and two keys; foundation gained the `Wave Nos.` series; Core gained
a `WHA Feature` enum value.

**Segment 2 added a second cross-feature read: wave management now reads labour management.** The
direction is one way — labour knows nothing about waves — and it is a *read of data*, not a call into
a feature: `WHA Labour Mgt.ExpectedMinutes` looks up a standard and applies it. A company that never
switched labour management on has no standards, every estimate is zero, and the wave falls back to
counting jobs exactly as segment 1 did. That is why the wave does not check whether labour management
is enabled: the data answers the question honestly on its own.

## Pre-replenishment — the wave card's one borrowed action

The wave card carries **Replenish for this wave**, which fills the pick faces the wave is about to
draw from before it goes out. The behaviour belongs to `FEAT-REPL-001` and is documented there; what
belongs here is the shape of the borrowing.

The action carries `ApplicationArea = WHAReplenishment` and an `AccessByPermission` on the
replenishment rule table — the same shape the handling unit card uses to carry labelling and quality
hold actions. A company without replenishment never sees it. Wave management gains a `using` for that
namespace and nothing else: it calls one procedure and knows nothing about rules, bins or demand.

## Templates — the same wave again tomorrow

A wave was a one-off. `WHA Wave Template` is the definition: this location, this strategy, this cap,
released or held. `CreateWave` builds a wave from it, fills it, and releases it when the template says
so.

Three decisions in it are worth arguing with:

- **A run that gathers nothing leaves no wave behind.** The wave is created, filled, found empty, and
  deleted; `Last Run At` is still stamped so it is clear the template ran. A scheduled round that
  produced an empty wave every quiet morning would fill the list with noise, and noise is what makes
  people stop reading it.
- **A template that has built waves cannot be deleted, only blocked.** The waves it built name it, and
  a wave pointing at a template that no longer exists is worse than a blocked row nobody uses.
- **`Release Automatically` is per template, not per warehouse.** An unattended morning round and a
  round somebody reviews before it goes out are different intentions, and a single setup flag could
  not express both.

### Scheduling is the job queue's, not ours

`WHA Wave Scheduler` is a `TableNo`-bound codeunit whose `OnRun` calls `RunScheduled`. A job queue
entry points at it, and Business Central decides when and how often — the entry's own `Location Code`
filter narrows the run to one location.

**Nothing in this feature stores a recurrence.** BC already knows how to schedule things, has a UI
for it, logs failures and handles time zones; a `Run at 06:00 daily` field here would be a worse
version of all of that, and one somebody would eventually have to reconcile with the job queue anyway.
What the feature owns is *what* to build; *when* belongs to the platform.

## Workload — minutes, not lines

`Max Tasks` counts jobs, and a count is a poor proxy for a shift: twenty pallet moves and twenty piece
picks are not the same afternoon. Segment 2 adds `Max Minutes`, worked out from the labour standards
that `FEAT-LAB-001` already holds — the first time one feature's engineered standards are used to plan
rather than to measure.

`Fill` applies both caps and stops at whichever binds first. Two details matter:

- **A job bigger than the whole allowance is still gathered, if the wave is empty.** Otherwise a
  thirty-minute job in a warehouse with a twenty-five-minute cap would never be gathered by any wave
  and would sit on the queue for ever. The first job always goes in; the cap governs everything after.
- **Zero minutes because nobody wrote a standard is not zero minutes of work.** `EstimateMinutes`
  returns a `Measured` flag alongside the number, and the wave card shows it. A wave whose work
  nothing measured says so, rather than presenting a confident zero.

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

## Role centre activities

This feature contributes its own tiles to the warehouse role centre: **waves being built and waves on the floor**. Four objects do it,
all of them in this feature's own folder — a `tableextension` adding the cue fields, an `enumextension`
registering the provider, a codeunit that counts, and a `pageextension` that puts the fields on the cue
part and writes the returned counts back.

**The foundation names none of them.** The seam, and why it is shaped this way, is in
[../FEAT-CORE-001-Foundation/technical-documentation.md](../FEAT-CORE-001-Foundation/technical-documentation.md).

The count runs in a read-only background session and its first line asks whether this feature is
switched on. A switched-off feature adds **nothing** rather than a zero, so its tiles never appear.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHAWaveManagement` bound to
`WHA Wave Feature Setup` (guided setup step 60); `Application Area Setup` gained
`WHA Wave Management` through this feature's own tableextension; the app-area subscriber sets it
from `Enabled`; the setup page is `ApplicationArea = All` while the wave pages carry
`WHAWaveManagement`. Every API write path and bound action calls `CheckEnabled`.

**The wave number series lives on this feature's own setup** (`WHA Wave Setup."Wave Nos."`), with
the feature's own application area, and this feature's guided-setup step creates `WHA-WAVE` when
numbering is asked for. The foundation neither creates it nor checks it.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Wave Management` | `waveManagement` | `WHA API Wave` | read, create, modify, and run fill / release / complete / cancel — **not delete** |
| `Warehouse Advanced - Wave Management` | `waveManagement` | `WHA API Wave Template` | **read only**, and run `buildWave` |
| `Warehouse Advanced - Demo Wave Management` | `demoWaveManagement` | `WHA API Demo Wave` | run `importDemoData` only |

Unlike the handheld, an agent **may** release a wave: that is a planning decision made at a desk
from information the agent can see, not a claim about where somebody was standing.

**Templates are read-only to an agent, but it may run one.** Building a wave from a template is a
decision somebody already made when they wrote the template; changing what a template does — the cap,
the strategy, whether it releases unattended — changes every wave it will ever build, and that is a
standing instruction to the warehouse rather than a day's planning.

## Demo data

`WHA Demo Wave` seeds three waves under fixed numbers `DEMO-WAVE-001..003`: one open and filled, one
filled and released, and one created but never used, plus one template `DEMO-MORNING` that builds the
morning round. It gathers from a location that already has released work, so the sample waves are not
empty on a company that has run the directed work sample data first. `Import()` also builds the
`WHA-WAVE` RapidStart package, which now carries the template table as well.

The sample template is **not** marked for the scheduled run. Sample data that starts building waves by
itself once somebody wires up a job queue entry is worse than sample data with a gap in it.

## Tests

`WHA Wave Tests` (codeunit 51004), 27 tests.

**Segment 1**, 17 tests: filling takes the most urgent work first and stops at the cap; work at other
locations, drafts, and work already in a wave are left alone; drafts are gathered and released when
the setup allows it; an empty wave cannot be released; a released wave cannot be changed or deleted;
taking work out of a wave leaves the job itself alone; a wave with work outstanding cannot be
completed but closes when its work is done; cancelling withdraws unstarted work; deleting an open wave
frees its work; the due-first strategy takes different work from the default; and demo idempotency.

**Segment 2**, 10 tests: a template builds a wave, fills it and is remembered by it; a template that
releases sends the wave straight to the floor; a template that finds no work leaves no wave behind but
still records that it ran; a blocked template builds nothing; a template that has built waves cannot
be deleted; the scheduled run builds only the templates marked for it; a wave measures its work
against the labour standards; a wave with no standards says plainly that its answer is not measured; a
wave stops gathering when it has a shift's worth of minutes; and a job bigger than the whole allowance
is still gathered rather than stranded.

## Not done

- **Workload is measured, not balanced.** A wave now knows how much work it holds; nothing spreads
  that work across operators. Balancing needs to know who is on shift and what they are already
  holding, which is a roster the app does not have and should not invent.
- **The estimate is only as good as the standards.** `Max Minutes` does nothing at all until somebody
  has written labour standards, and a warehouse that has not will see a cap that never binds. The wave
  card says so rather than letting a silent zero look like an answer.
- **Nothing warns that a template is producing nothing.** A template whose location has been renamed,
  or whose strategy no longer matches any work, quietly returns zero every morning. `Last Run At`
  moves and `Last Wave No.` stays empty, and reading that is a person's job.
- **The scheduled run is all or nothing per template.** There is no "only on weekdays" or "only after
  the morning receipt has been put away" — those are job queue entries or a condition nobody has
  specified yet.
- **Automatic completion.** See above — deliberate, but it means the list needs running or a job
  queue entry to stay honest.
- **No wave on the handheld.** An operator is handed work by the queue and never sees which wave it
  came from. Whether they should is an operator-review question.
- **Getting-started in the customer language** — the language has not been confirmed.
