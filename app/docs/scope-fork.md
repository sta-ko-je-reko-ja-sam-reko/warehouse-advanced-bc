# The scope fork: beside Business Central's warehouse, or on top of it

The one architectural decision this project has never taken, written down so it can be. Three separate
pieces of work ran into it and each recorded it as somebody else's problem —
[location-configuration.md](location-configuration.md) twice, and the document-source work once.

## The question

The app keeps **its own queue of work**: `WHA Warehouse Task`. Business Central keeps its own —
`Warehouse Activity Line`, the lines behind a put-away, a pick, a movement, an inventory put-away or
pick. Both describe an operator walking to a bin and moving something.

Does the app go on keeping a queue **beside** Business Central's, or does it start working **on top of**
Business Central's?

## Why it matters more than it sounds

Because of what it currently costs. Business Central raises its own activities at any location with
`Require Put-away` or `Require Pick`, and **forces both on** at a `Directed Put-away and Pick` location
with no way to turn them off. The app therefore refuses to raise work at exactly those locations, and
the consequences are already documented:

| Business Central document | Location it needs | Reachable by this app today |
|---|---|---|
| Warehouse receipt, warehouse shipment | `Require Receive` / `Require Shipment` | Yes |
| Movement worksheet | `Bin Mandatory` | Yes |
| Whse. internal put-away, internal pick | `Require Put-away`/`Pick` **and** directed | **No** |
| Warehouse pick for production or assembly | `Require Pick` | **No** |
| Anything at all at a directed location | — | **No** |

Read the last row plainly: **the app is excluded from precisely the warehouses that most need a
warehouse management system.** A site big enough to run directed put-away and pick is a site with
zones, bin ranking, break-bulk and put-away templates — and this app cannot raise a single job there.
It works at the simple locations, which are the ones Business Central already handles adequately on its
own.

That is the strategic problem. It is not a missing feature; it is the shape of the app.

## What is actually true today

- `WHA Warehouse Task` is referenced by **51 files across eight features** — directed work, waves,
  replenishment, mobile device, integration, analytics, slotting, labour. It is the spine.
- The app **never reads or writes** `Warehouse Activity Line`. Not once.
- Registering a Business Central activity is not hard: `Whse.-Activity-Register` (codeunit 7307) takes a
  filtered set of `Warehouse Activity Line` and has no dialog. The UI wrapper
  `Whse.-Act.-Register (Yes/No)` (7306) adds only `CheckSourceDocument`,
  `WMS Management.CheckBalanceQtyToHandle` and a confirmation. Doing what 7306 does without the
  confirmation is the same move already made with `Whse. Jnl.-Register Line` in warehouse registration:
  use Business Central's engine, keep its rules, skip the dialog.

## The three options

### A — stay beside it

Change nothing. The app remains a parallel queue, correct only where Business Central raises no
activities of its own.

- **Costs nothing.** Everything built works as it does.
- **Caps the product** at non-directed locations with put-away and pick switched off, and permanently
  excludes production, assembly and internal warehouse documents.

### B — become it

The app replaces Business Central's put-away and pick: its own bin selection, put-away templates, break
bulk, pick availability.

- **Unlocks everything**, and owns everything.
- **Re-writes a large, mature and subtle part of Business Central.** The `Breakbulk No.` field on the
  activity line is one hint at the depth; bin ranking, put-away templates, `Allow Breakbulk`, and the
  availability calculations behind `CalcTotalAvailQtyToPickForDirectedPutAwayPick` are others. A product
  with no customer and no test run has no business taking that on.

### C — work on top of it

Business Central raises the activity, as it already does. **The app executes it**: reads the activity
lines, presents them on the handheld, measures the labour, batches them into waves — and when the
operator finishes, **registers the Business Central activity**.

- **Unlocks every row in the table above**, because everything in it ends up as a `Warehouse Activity
  Line` sooner or later.
- **Removes the double-queue hazard rather than guarding against it.** There is one queue; the app no
  longer interprets the document independently.
- **Keeps what actually differentiates the app** — handling units, waves, labour standards, slotting,
  analytics, the handheld, dock and yard, quality hold, counting, labelling, integration. None of that
  exists in Business Central, and none of it depends on owning the queue.

## Recommendation: C

Business Central already owns bin-level stock — that was decided in
[warehouse-registration.md](warehouse-registration.md), and the whole app was reshaped around it. **The
same reasoning applies to warehouse work.** Where Business Central models the job, it should own the
job, and this app should be the thing that makes the job pleasant to do and measurable afterwards.

Option A settles for the warehouses that need this app least. Option B rebuilds the part of Business
Central that is hardest to rebuild and least in need of rebuilding.

## What C would look like as work

**It is incremental, and the first segment is small.** The task table keeps its shape.

1. **A task source that reads `Warehouse Activity Line`.** `WHA ITaskSource` already exists and already
   has four implementations; this is a fifth. `Generate` reads the activity's lines instead of a
   document's, and the task carries the activity type, number and line number.
2. **Completion registers the activity.** `WriteBack` sets `Qty. to Handle` on the Take and Place lines
   and calls `Whse.-Activity-Register`, after `CheckBalanceQtyToHandle` — the pair must balance, which
   is precisely the rule a handheld must respect.
3. **The location guard inverts for this source.** Today raising work is refused where Business Central
   raises its own activities. For this source that condition is *required* rather than refused.
4. **Warehouse registration steps aside for it.** Registering the activity writes the warehouse entries
   itself, so the app must not also register a movement — the same "half of it is worse than neither
   half" rule already applied to posting.

Everything reading `WHA Warehouse Task` — waves, labour, analytics, slotting, the handheld — keeps
working untouched, because the task table is still the task table. That is the whole reason to take C
this way rather than by replacing the spine.

## What this does not settle

- **Two records of one job can still drift.** If somebody registers the activity in Business Central
  directly, the app's task is stale. `SourceIsOpen` already exists for exactly this and would answer it,
  but nothing acts on that answer yet.
- **Break-bulk lines** turn one job into several with a shared `Breakbulk No.`, and the handheld has
  never been shown one.
- **Item tracking on an activity line** lives in `Whse. Item Tracking Line`, which this app has never
  touched.
- **Whether the app's own task queue should still raise work from documents at all** once C exists. Two
  sources for the same receipt would be the double queue again, from the other direction. The honest
  answer is probably that the document sources become the *non-directed* path and the activity source
  the *directed* one, chosen by the location rather than by a setting.

## What would change this recommendation

A customer who runs only simple locations and wants nothing Business Central's warehouse offers. That
customer does not exist yet — [there is no customer](implementation-plan.md), which is exactly why this
should be decided on the merits of the product rather than deferred again.
