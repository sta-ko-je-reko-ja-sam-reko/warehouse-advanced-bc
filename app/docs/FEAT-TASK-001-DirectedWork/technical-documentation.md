# FEAT-TASK-001 - Directed Work

## Source/legacy reference

N/A (greenfield).

> **Scope note.** This feature was built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> The capability discovery (Phase 0) has not been run. Directed work was chosen as the first
> Wave B item because it is what [FEAT-HU-001](../FEAT-HU-001-HandlingUnits/technical-documentation.md)
> was built to feed, and because the mobile device feature above it is a presentation layer over this
> queue rather than a separate model. If this customer directs work from paper lists or from the
> standard warehouse activity documents, the queue below needs re-scoping before it is extended.

## Business process

Standard Business Central directs warehouse work through *documents* — a warehouse receipt, a pick,
a put-away, a movement. Each is a document with lines, tied to a source document, and each is worked
by whoever opens it. There is no queue: nothing ranks the outstanding work, nothing hands the next
piece of it to the person who just finished something, and nothing records who did what and when.

This feature adds that queue:

1. A **warehouse task** is created and receives a number from this feature's own number series. It says
   what kind of work it is, where it happens, and what is being moved — a handling unit, or an item
   and a quantity.
2. It carries a **priority** and optionally a **due date**. A lower priority number is more urgent.
3. It is **released** when it is ready for the floor. Until then it can be reviewed and changed.
4. It is **assigned** to a person, who **starts** it and then **completes** it. Each step is stamped
   with the time it happened.
5. Asking for work — *Get next task* — hands back the operator's own unfinished work first, and only
   then the most urgent released task, assigning it on the way out.
6. Completing a task that carries a handling unit **moves that unit** to the destination bin the task
   named, so the two features agree on where the goods are.

A task that is no longer wanted is **cancelled**, not deleted: a task that has been started or
completed cannot be deleted at all, because it is the record that the work happened.

### Delivered so far

**Segment 1** — the task entity, its life cycle, the priority queue, operator assignment, and the
handling unit move on completion.
**Segment 2** — partial completion: a job finished with less than it asked for, and why.
**Segment 3** — the source document: work raised from a standard warehouse receipt or shipment, and a
job that knows which document and which order it is serving. This is the segment that turns the queue
into an execution layer rather than a list somebody types into.
**Segment 4** — writing back: finishing a job fills in the quantity to receive or to ship on the
document it came from, behind a setting that ships off. See *Writing back* below.
**Segment 5** — item tracking on a job: the lot and serial fields, filled in where the answer is
knowable. See *Item tracking on a job* below.
**Segment 6** — warehouse registration: finishing a job registers a warehouse movement, so Business
Central's own bin content and warehouse entries follow the floor instead of standing still. Shared
machinery, described in [warehouse-registration.md](../warehouse-registration.md); this feature owns
the setting and the call site.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Warehouse Task Setup` | 50200 | Single-record feature setup: enablement and queue rules |
| `WHA Warehouse Task` | 50201 | One piece of work |

### `WHA Warehouse Task`

| Field | Type | Notes |
|---|---|---|
| `No.` | `Code[20]` | Primary key, assigned from this feature's own number series |
| `Task Type` | `Enum "WHA Warehouse Task Type"` | Put-away / Pick / Movement / Replenishment / Count |
| `Description` | `Text[100]` | What the operator is being asked to do |
| `Location Code` | `Code[10]` | `TableRelation = Location`. Changing it clears **both** bins |
| `From Bin Code` / `To Bin Code` | `Code[20]` | Filtered to the task's location |
| `Handling Unit No.` | `Code[20]` | The unit being moved. Setting it copies the unit's location and bin |
| `Item No.` / `Variant Code` | `Code[20]` / `Code[10]` | The goods, when the task is not about a whole unit |
| `Quantity` / `Unit of Measure Code` | `Decimal` / `Code[10]` | Non-negative; the unit of measure comes from the item |
| `Quantity Handled` | `Decimal` | What was **actually** moved. Set on completion, not editable |
| `Short Reason` | `Enum "WHA Whse. Short Reason"` | Why the rest was not moved |
| `Status` | `Enum "WHA Warehouse Task Status"` | Created / Released / Assigned / In progress / Completed / Cancelled. Not editable — the actions move it |
| `Priority` | `Integer` | Lower is more urgent. Defaults from the setup |
| `Due Date` | `Date` | Breaks ties between tasks of equal priority |
| `Source Type` | `Enum "WHA Task Source"` | What kind of document raised the work. **Extensible**; a task typed in by hand says *created by hand* |
| `Source No.` / `Source Line No.` | `Code[20]` / `Integer` | The warehouse document and line the work was read from |
| `Source Document No.` | `Code[20]` | The order the warehouse document is serving — the purchase or sales order somebody is actually waiting on |
| `Assigned To User ID` | `Code[50]` | `TableRelation = User."User Name"`. Clearing it returns the task to the queue |
| `Assigned At` / `Started At` / `Completed At` | `DateTime` | Stamped by the life cycle, not editable |

Keys: `PK` on `No.` (clustered), plus `Queue` (`Status`, `Location Code`, `Priority`, `Due Date`),
`Assignment` (`Assigned To User ID`, `Status`, `Priority`), `HandlingUnit` (`Handling Unit No.`), and
`Source` (`Source Type`, `Source No.`, `Source Line No.`) — the last of which is what makes raising
work from the same document twice cheap as well as harmless.

**The `Queue` key is the feature.** It is the index the *Get next task* answer is read from, in one
`FindFirst` — status first so only released work is scanned, then location so an operator sees only
their part of the warehouse, then priority and due date, which is the order work should be done in.

### Number series

The warehouse task number series lives on **this feature's own setup**
(`WHA Warehouse Task Setup."Warehouse Task Nos."`), with the feature's own application area, and the
feature's guided-setup step creates the `WHA-TASK` series when numbering is asked for. Inserting a
task with no number errors if that series is unset.

### `WHA Warehouse Task Setup`

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Default Priority` | Given to a task created without one. Ships as 100, so more and less urgent work both fit around it |
| `Auto Release Tasks` | Releases a new task as it is created — but only if it already names a location and something to move, so a half-built task never reaches the floor |
| `Follow Up Short Picks` | Raises a new task for whatever an operator could not find. Off by default — see below |
| `Max Open Tasks Per User` | How many assigned or in-progress tasks one person may hold. Zero means no limit |
| `Whse. Registration Method` | What finishing a job tells Business Central about the goods that moved. Ships as *Do not tell Business Central*, which is what the app always did. See [warehouse-registration.md](../warehouse-registration.md) |
| `Open Work On Posting` | What happens when a warehouse receipt or shipment is posted while jobs raised from it are still open. Ships as *Let the document be posted*, which is what the app always did |
| `Who May Be Given Work` | Whether a task may be assigned to anybody, or only to somebody Business Central lists as a warehouse employee at that location. Ships as *Anybody with permission to use the app*, which is what the app always did |

**No task history table.** The stamps on the task are the audit trail for segment 1. A separate
history/event table becomes worth its cost when labour management (`FEAT-LAB-001`) needs indirect
time and per-step durations; it would be the wrong shape to guess at now.

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Warehouse Task Setup` | table | 50200 | `app/src/DirectedWork/tables/WarehouseTaskSetup.Table.al` |
| `WHA Warehouse Task` | table | 50201 | `app/src/DirectedWork/tables/WarehouseTask.Table.al` |
| `WHA Warehouse Task Type` | enum | 50200 | `app/src/DirectedWork/enums/WarehouseTaskType.Enum.al` |
| `WHA Warehouse Task Status` | enum | 50201 | `app/src/DirectedWork/enums/WarehouseTaskStatus.Enum.al` |
| `WHA IWarehouseTask` | interface | — | `app/src/DirectedWork/interfaces/IWarehouseTask.Interface.al` |
| `WHA Warehouse Task Logic` | codeunit | 50200 | `app/src/DirectedWork/codeunits/WarehouseTaskLogic.Codeunit.al` |
| `WHA Task Feature Setup` | codeunit | 50201 | `app/src/DirectedWork/codeunits/TaskFeatureSetup.Codeunit.al` |
| `WHA Task App Area Sub.` | codeunit | 50202 | `app/src/DirectedWork/codeunits/TaskAppAreaSub.Codeunit.al` |
| `WHA Demo Warehouse Task` | codeunit | 50203 | `app/src/DirectedWork/codeunits/DemoWarehouseTask.Codeunit.al` |
| `WHA Task Source` | enum | 50203 | `app/src/DirectedWork/enums/TaskSource.Enum.al` |
| `WHA ITaskSource` | interface | — | `app/src/DirectedWork/interfaces/ITaskSource.Interface.al` |
| `WHA Src Manual` | codeunit | 50204 | `app/src/DirectedWork/codeunits/SrcManual.Codeunit.al` |
| `WHA Src Whse. Receipt` | codeunit | 50205 | `app/src/DirectedWork/codeunits/SrcWhseReceipt.Codeunit.al` |
| `WHA Src Whse. Shipment` | codeunit | 50206 | `app/src/DirectedWork/codeunits/SrcWhseShipment.Codeunit.al` |
| `WHA Task Source Mgt.` | codeunit | 50207 | `app/src/DirectedWork/codeunits/TaskSourceMgt.Codeunit.al` |
| `WHA Whse. Receipt Tasks` | pageextension | 50200 | `app/src/DirectedWork/pageextensions/WhseReceiptTasks.PageExt.al` |
| `WHA Whse. Shipment Tasks` | pageextension | 50201 | `app/src/DirectedWork/pageextensions/WhseShipmentTasks.PageExt.al` |
| `WHA Task Appl. Area Setup` | tableextension | 50200 | `app/src/DirectedWork/tableextensions/TaskApplAreaSetup.TableExt.al` |
| `WHA Warehouse Task Setup` | page | 50200 | `app/src/DirectedWork/pages/WarehouseTaskSetup.Page.al` |
| `WHA Warehouse Task Card` | page | 50201 | `app/src/DirectedWork/pages/WarehouseTaskCard.Page.al` |
| `WHA Warehouse Tasks` | page | 50202 | `app/src/DirectedWork/pages/WarehouseTasks.Page.al` |
| `WHA API Warehouse Task` | page | 50203 | `app/src/DirectedWork/pages/APIWarehouseTask.Page.al` |
| `WHA API Demo Warehouse Task` | page | 50204 | `app/src/DirectedWork/pages/APIDemoWarehouseTask.Page.al` |
| `WHA Warehouse Task Tests` | codeunit | 51001 | `test/src/codeunits/WarehouseTaskTests.Codeunit.al` |
| `WHA Task Activities Cue` | tableextension | 50201 | `app/src/DirectedWork/tableextensions/TaskActivitiesCue.TableExt.al` |
| `WHA Task Activity Provider` | enumextension | 50200 | `app/src/DirectedWork/enumextensions/TaskActivityProvider.EnumExt.al` |
| `WHA Task Activity Cues` | codeunit | 50208 | `app/src/DirectedWork/codeunits/TaskActivityCues.Codeunit.al` |
| `WHA Task Activities` | pageextension | 50202 | `app/src/DirectedWork/pageextensions/TaskActivities.PageExt.al` |
| `WHA Task Whse. Registration` | codeunit | 50209 | `app/src/DirectedWork/codeunits/TaskWhseRegistration.Codeunit.al` |
| `WHA Whse. Registration Tests` | codeunit | 51017 | `test/src/codeunits/WhseRegistrationTests.Codeunit.al` |
| `WHA Test Whse. Reg. Recorder` | codeunit | 51016 | `test/src/codeunits/TestWhseRegRecorder.Codeunit.al` |

All in namespace `WarehouseAdvanced.DirectedWork`, from the reserved block `50200..50249`.

Core objects changed in the same pass: `WHA Feature` gained a value. Numbering was originally added
to Core as well; it has since moved to this feature's own setup, so Core no longer knows this feature
numbers anything.

**Segment 3 introduced the first `pageextension` in the app.** Until now nothing this project ships
appeared anywhere in standard Business Central; from here, two standard pages carry one action each.
That is a threshold worth noticing rather than a detail — the app is now visible to a user who never
opens any of its own pages, and every future extension of a standard page inherits the argument made
below about why this one is a button and not a subscriber.

## Logic

All table triggers and field validations delegate a single line to `Logic()`, resolved through
`WHA IWarehouseTask` with a public `Define()` for injection. The rules live in
`WHA Warehouse Task Logic`:

| Operation | Behaviour |
|---|---|
| `Trigger_OnInsert` | Assigns the number from this feature's series; applies the default priority; releases the task if the setup says so **and** it is ready for work |
| `Trigger_OnDelete` | Refuses to delete a task that is in progress or completed |
| `Validate_LocationCode` | Clears both bins when the location actually changes |
| `Validate_HandlingUnitNo` | Refuses a shipped unit; copies the unit's location and bin onto the task |
| `Validate_ItemNo` | Clears the variant and unit of measure, then copies the base unit of measure from the item |
| `Validate_Quantity` / `Validate_Priority` | Reject negative values |
| `Validate_AssignedToUserID` | Refuses to assign work that is not released, or that is already being done; enforces the per-user limit; stamps `Assigned At`; clearing the user returns the task to `Released` |
| `Release` | Created → Released. Refuses a task with no location, or with nothing to move |
| `Assign` | Validates the user through the field, then modifies |
| `Start` | Assigned → In progress, stamping `Started At` |
| `Complete` | In progress → Completed, stamping `Completed At` and `Quantity Handled` in full, then moves the handling unit |
| `CompleteShort` | In progress → Completed with **less** than was asked for, recording how much and why, and raising a follow-up if the setup asks for one |
| `Cancel` | Anything not already completed or cancelled → Cancelled |
| `GetNextForUser` | The operator's in-progress work, then their assigned work, then the most urgent released task at the location — which is assigned to them as it is handed over |

**Status is moved by operations, not by typing.** The field is `Editable = false` on the table, so
the UI, the API and any dependent extension all go through the same five transitions. That is what
makes the stamps trustworthy.

**Assignment is a field validation, not just an action.** Whether the change comes from the card, a
`PATCH` on the API, or `GetNextForUser`, it lands in `Validate_AssignedToUserID` and gets the same
checks. `Assign` is a thin wrapper that validates and modifies.

### Partial completion — what a short pick does and does not do

An operator sent for twelve who finds four reports the job **short**: it closes as *Completed* with
`Quantity Handled = 4` and a reason. Three decisions worth arguing with:

- **`Quantity` is never rewritten.** It stays as the record of what was asked for; `Quantity Handled`
  is what happened. Overwriting the ask would destroy the only evidence there was a shortfall.
- **A short pick closes the job — it is not a hand back.** An empty bin is an *answer*, and the
  office needs it. Handing back instead sends the next operator to the same empty bin.
- **The outstanding quantity is reported, not automatically re-queued.** `Follow Up Short Picks` is
  **off** by default, because re-raising work for stock that is not there is how a warehouse gets
  busy without getting anything done. Switched on, the follow-up carries the outstanding quantity,
  the same location, bins, item and priority, and a description naming the task it came from.
  Whether that follow-up reaches the floor is decided by `Auto Release Tasks` as for any other task.

Whole-unit jobs — a task naming a handling unit and no quantity — **cannot** be short: there is no
partial version of moving a pallet, and `CompleteShort` says so rather than pretending.

`WHA Whse. Short Reason` is extensible and its values are **a guess at how this warehouse talks**
(nothing in the bin, not enough, damaged, cannot reach it). The operator review script asks for the
words operators actually use; expect to replace these with them.

### Where this touches handling units

Two places, both one-directional — directed work reads handling units, never the reverse:

- **Planning:** naming a handling unit on a task copies its location and bin onto the task, and
  refuses a unit that has already shipped.
- **Completion:** completing a task that names a unit sets that unit's location and bin to the task's
  destination, through `Validate`, so the handling unit's own rules still run.

Nested units are **not** walked. Moving a pallet does not rewrite the location of the cartons inside
it, because a nested unit's position is defined by its parent, not by its own location field.

Completion has a third step, and its **ordering is load-bearing**: the move is handed to warehouse
registration *before* the handling unit is moved, because the bin the goods came from is readable
then and is not afterwards. It also means a move Business Central refuses stops the completion, so
the app never records a pallet in a bin that Business Central rejected. A job naming a unit registers
every line on that unit, because moving the pallet moves all of it; a job naming only an item
registers that item at the quantity actually handled.

## The source document — where work comes from

Standard Business Central already knows what has arrived and what is due to leave; it just has no
queue to put it on. Segment 3 reads those documents and raises tasks, behind an extensible seam so
that *which* documents and *what they become* can be replaced without touching the queue.

`WHA Task Source` is an extensible enum implementing `WHA ITaskSource`:

| Value | Implementation | Reads | Raises |
|---|---|---|---|
| `WHAManual` (0) | `WHA Src Manual` | nothing | nothing — a task somebody typed |
| `WHAWhseReceipt` | `WHA Src Whse. Receipt` | `Warehouse Receipt Line` | a **put-away** per outstanding line, out of the bin the receipt names |
| `WHAWhseShipment` | `WHA Src Whse. Shipment` | `Warehouse Shipment Line` | a **pick** per outstanding line, into the bin the shipment names |

The interface is five methods — `Generate`, `Describe`, `DescribeLink`, `SourceIsOpen`, `ShowSource` —
and `WHA Task Source Mgt.` is the only thing the rest of the app calls. Nothing outside the three
implementations names a warehouse receipt or a warehouse shipment.

`WHAManual` being value 0 matters: every task that already exists, and every task anybody types from
now on, reads as *created by hand* without an upgrade step, and answers the interface honestly —
no document to name, nothing outside the app that can finish it.

### One bin, not two, and why

A put-away raised from a receipt sets `From Bin Code` and leaves `To Bin Code` blank. A pick raised
from a shipment does the reverse. The missing half is not an oversight: **where goods should go, and
where they should be taken from, is a question about stock and about the shape of the warehouse — not
a question the document can answer.** Guessing it here would put a wrong bin in front of an operator,
which is worse than putting none. Bin choice is what `FEAT-SLOT-001` exists to have an opinion about,
and this is the seam it will eventually plug into.

### The movement worksheet

A movement worksheet line is already the shape of a warehouse task — a from-bin, a to-bin, an item and
a quantity — so it comes across as a `WHAMovement` with both ends intact, which no other source can
give. It needs only `Bin Mandatory` at the location, which is why it is reachable when Business
Central's other internal documents are not.

Its write-back is **the only one in the app guarded on something other than a setting**, and the reason
is a hazard rather than a preference. The line exists to be turned into a Business Central movement; if
this app walks the move and leaves the line outstanding, whoever creates a movement from that worksheet
next moves the same goods a second time. So the line is marked handled — but only when warehouse
registration is actually maintaining bin content, because that is exactly when the goods really did move
somewhere Business Central can see. With registration off the line is left alone, since claiming a move
Business Central never saw would be worse than the duplication the write-back exists to prevent.

The worksheet is found by name, filtered to the first template of type Movement. A location with two
movement worksheet templates carrying the same worksheet name is ambiguous, and the app takes the first
— worth knowing, and not worth a field on the task to fix until somebody has such a warehouse.

### Where the app may raise work at all

Business Central raises put-aways and picks of its own at a location with `Require Put-away` or
`Require Pick` — posting a receipt there calls `Create Put-away`, and a shipment cannot be posted for
more than has been picked. Raising warehouse tasks from the same document would put two queues over
the same goods with neither able to see the other, so both document sources **refuse** such a location
with an error that names it.

The consequence worth knowing is the one this does not fix: turning on `Directed Put-away and Pick`
forces all four *Require* flags on, and Business Central will not let them back off. **Directed work
cannot be used at a directed location.** Counting, quality hold and their posting still can. See
[../location-configuration.md](../location-configuration.md).

### A button, not a subscriber

Work is raised by a person pressing **Create warehouse tasks** on the warehouse receipt or shipment.
Nothing happens automatically on release or on posting, even though subscribing to a Microsoft
publisher is allowed and would have been easy.

That is the same judgement wave completion, label assignment and count posting all made: **until
Phase 0 says how this warehouse actually receives and ships, an automatic trigger is a guess that
fires by itself.** A button is a guess somebody chose. The seam is already in place, so making it
automatic later is a subscriber whose body is one line — not a redesign.

### Raising work twice is harmless

`HasOpenTask` checks the `Source` key for a task on the same line that nobody has cancelled. So:

- Pressing the button again raises nothing.
- A line added to the document afterwards raises its own job and only that.
- A job **cancelled** in error leaves its line uncovered, and the document can raise it again — which
  is the behaviour that makes cancelling safe rather than final.

### Noticing work nobody needs

`SourceIsOpen` asks the document whether the line still has anything outstanding. A receipt received
or a shipment shipped by some other route leaves a task on the queue that is now a walk for nothing,
and the task card says so under **Still wanted**.

**Nothing acts on that answer yet** — no automatic cancellation, no warning when an operator picks
the job up. Deciding what should happen to stale work is a question about how much the warehouse
trusts the link, and that is a conversation to have after the link has run against real documents.

## Role centre activities

This feature contributes its own tiles to the warehouse role centre: **jobs waiting, jobs being done, and jobs past their date**. Four objects do it,
all of them in this feature's own folder — a `tableextension` adding the cue fields, an `enumextension`
registering the provider, a codeunit that counts, and a `pageextension` that puts the fields on the cue
part and writes the returned counts back.

**The foundation names none of them.** The seam, and why it is shaped this way, is in
[../FEAT-CORE-001-Foundation/technical-documentation.md](../FEAT-CORE-001-Foundation/technical-documentation.md).

The count runs in a read-only background session and its first line asks whether this feature is
switched on. A switched-off feature adds **nothing** rather than a zero, so its tiles never appear.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`:

- `WHA Feature` gained value `WHADirectedWork`, bound to `WHA Task Feature Setup` via the interface.
  That is what registers the guided setup step (step 30) and answers `IsEnabled` — **no Core
  dispatch code changed**, only the enum gained a value.
- `Application Area Setup` gained `WHA Directed Work` through a **second** tableextension on that
  table, owned by this feature. One extension per feature keeps the features separable.
- `WHA Task App Area Sub.` sets that boolean from the feature's `Enabled` on experience-tier refresh,
  subscribing with `SkipOnMissingLicense`/`SkipOnMissingPermission` both `true`.
- **The setup page is `ApplicationArea = All`**; the card and list carry `WHADirectedWork`. The
  `Enabled` field inherits `All` while the queue fields take the feature area.
- The API page guards `OnInsertRecord`/`OnModifyRecord`/`OnDeleteRecord` **and every bound action**
  with `CheckEnabled`, because application areas do not reach the API path. Reads stay open.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Directed Work` | `directedWork` | `WHA API Warehouse Task` | read, create, modify, delete, and run the four life cycle actions |
| `Warehouse Advanced - Demo Directed Work` | `demoDirectedWork` | `WHA API Demo Warehouse Task` | run `importDemoData` only |

The demo importer is deliberately in its **own** configuration and its **own** API group.

Registration goes through `WHA IFeatureSetup.RegisterMcpConfiguration`, so the feature owns its
configuration and Core needs no per-feature knowledge.

Agent instructions ship as companion documents:
[../agent-instructions/WarehouseAdvanced-DirectedWork.md](../agent-instructions/WarehouseAdvanced-DirectedWork.md)
and [../agent-instructions/WarehouseAdvanced-Demo-DirectedWork.md](../agent-instructions/WarehouseAdvanced-Demo-DirectedWork.md).
**Changing the tools in these configurations is not done until those files are updated in the same
change.**

## Demo data

`WHA Demo Warehouse Task` seeds six sample tasks with fixed numbers `DEMO-TASK-001..006`, covering
every task type, every status, both ways of saying what is moved, an explicit priority, a defaulted
priority, and a due date. Each insert is guarded by `if Rec.Get(...) then exit;`, so the import is
idempotent.

The sample data **loads what it can**: location, bins, item and handling unit are taken from whatever
the company already has, and a task is created without them if it has none. Statuses beyond
*Released* need a `User` record for the current user; where there is none, the tasks stop at the
status they can reach. The tasks are driven through the **real life cycle operations**, never by
writing `Status` directly — so the sample data cannot show a state the rules would not allow.

**One seeder, two front doors**, never forked:

| Path | Caller |
|---|---|
| End user | The guided setup wizard's sample-data opt-in → `ApplyChoices` → `Import()` |
| Agent | `WHA API Demo Warehouse Task.ImportDemoData` (MCP tool) → `Import()` |

`Import()` also builds the feature's RapidStart configuration package (`WHA-TASK`) containing
`WHA Warehouse Task` only — built **inside `Import()`**, never eagerly on install, and never
including the `Setup` table.

## Tests

`WHA Warehouse Task Tests` (codeunit 51001). The validation rules are asserted directly against the
logic codeunit with unsaved records — no database writes; the life cycle, queue and cross-feature
tests use real records and rely on the test runner's rollback.

| Test | Asserts |
|---|---|
| `LocationChangeClearsBothBins` / `SameLocationKeepsBins` | Bins follow the location |
| `NegativeQuantityIsRejected` / `NegativePriorityIsRejected` | Neither value may go below zero |
| `ChangingItemClearsVariantAndUnitOfMeasure` | A variant of the previous item cannot survive |
| `ReleaseWithoutLocationIsRejected` / `ReleaseWithNothingToMoveIsRejected` | A task must be complete enough to work before it reaches the floor |
| `AssigningAnUnreleasedTaskIsRejected` | Unreleased work cannot be handed out |
| `AssigningMovesTaskToAssigned` / `ClearingTheUserReturnsTaskToTheQueue` | Assignment moves the status both ways and stamps the time |
| `StartingAnUnassignedTaskIsRejected` / `CompletingATaskThatIsNotStartedIsRejected` | The life cycle cannot be skipped |
| `CompletedTaskCannotBeCancelled` / `CompletedTaskCannotBeDeleted` | Finished work is a record, not a draft |
| `NewTaskTakesTheDefaultPriority` | The setup default reaches a new task |
| `AutoReleaseNeedsSomethingToWorkOn` / `AutoReleasePutsAReadyTaskOnTheFloor` | Automatic release fires only for a task that is ready |
| `LifeCycleRunsFromReleaseToCompletion` | The whole walk, with its stamps |
| `MostUrgentTaskIsOfferedFirst` | The queue order is priority, and handing work over assigns it |
| `OwnUnfinishedWorkComesBackFirst` | Started work outranks more urgent new work |
| `CompletingMovesTheHandlingUnit` | The cross-feature move actually lands on the unit |
| `ShippedHandlingUnitCannotBeGivenWork` | A shipped unit is out of scope for new work |
| `UserTaskLimitIsEnforced` | The per-user limit blocks the second assignment |
| `HandingBackStartedWorkReturnsItToTheQueue` | Abandoned work returns to the queue and stops claiming it was started |
| `ShortPickRecordsWhatWasActuallyMoved` | Four of twelve closes at four, with the ask left intact |
| `CompletingInFullRecordsTheWholeQuantity` | Every finished task can be read the same way |
| `ShortPickCannotClaimMoreThanWasAsked` | Short is for finding less, never more |
| `AJobWithNoQuantityCannotBeShort` | A pallet move is all or nothing |
| `NoFollowUpIsRaisedUnlessTheSetupAsksForOne` / `AFollowUpCarriesTheOutstandingQuantity` | The re-queue decision is configuration, both ways |
| `RaisingWorkFromAReceiptPutsAPutAwayOnTheQueue` | A receipt line becomes a put-away out of the bin it named, and nothing decides where it goes |
| `RaisingWorkFromAShipmentPutsAPickOnTheQueue` | A shipment line becomes a pick into the bin it named, and nothing decides where it comes from |
| `ALineWithNothingOutstandingRaisesNoWork` | A finished line is not work, and raising nothing is not an error |
| `RaisingWorkTwiceAddsOnlyWhatIsMissing` | The button is safe to press twice, and a line added afterwards raises only itself |
| `WorkThatWasCancelledCanBeRaisedAgain` | Cancelling a job in error is recoverable from the document |
| `AJobRemembersTheOrderBehindTheDocument` | The order somebody is waiting on survives onto the floor |
| `AJobWhoseSourceLineIsFinishedIsNoLongerWanted` | Work overtaken by events can be noticed |
| `AJobPutOnTheQueueByHandHasNoDocumentBehindIt` | Segment 1 work still behaves, and says honestly that it has no source |
| `RaisingWorkFromADocumentThatIsNotThereIsRefused` | A missing document is an error, not an empty answer |
| `NothingFoundAtAllStillClosesTheJob` | An empty bin is an answer, not a hand back |
| `DemoImportIsIdempotent` / `DemoImportCoversEveryTaskType` | The seeder is safe to re-run and covers the enum |

## Writing back — where the app stops being an overlay

Segment 3 raised work *from* a document and finishing it told the document nothing. This closes that
loop, and it is a bigger step than the code makes it look: filling in `Qty. to Receive` or
`Qty. to Ship` means the warehouse app decides what Business Central is about to post.

So it is **asked for, not assumed**. `Write back to the document` on the warehouse task setup ships
**off**, which is the behaviour this app has always had, and turning it on is a decision about who
owns the document rather than a preference.

`WHA ITaskSource` gained `WriteBack`, so what writing back *means* stays with the source that knows
the document: the receipt implementation fills in `Qty. to Receive`, the shipment one
`Qty. to Ship`, and a hand-made job answers no to both because it has no document to answer to.

Three properties are deliberate:

- **It adds rather than sets.** A line finished short raises a follow-up, and both jobs serve the
  same line. A second write that replaced the first would make four already put away disappear from
  the document.
- **It never goes past what the line has outstanding.** A quantity larger than the line wants is
  capped rather than refused, because the job is already finished by the time this runs and failing
  here would leave the warehouse right and the document wrong with nothing to do about it.
- **A job that moved nothing writes nothing.** A short pick of zero leaves the document alone.

`Written Back` on the task records that it happened, so a job that changed a document can be told
from one that did not — a job finished while the setting was off, or a job with no document behind
it, both read as blank rather than as false-and-therefore-broken.

## Who may be given work

Business Central keeps a `Warehouse Employee` list — one row per user per location — and its own
warehouse pages will not let anybody else in. This app kept its own queue and never consulted it, so a
person could hold and finish a job at a location Business Central would have turned them away from.

`Who May Be Given Work` decides. It ships as **Anybody with permission to use the app**, which is what
the app has always done, and the other value applies Business Central's rule.

Two things about how it is built:

- **The list is read directly, not through `CheckUserIsWhseEmployeeForLocation`.** Business Central's
  own check offers to open the Warehouse Employees page and only errors if the answer is no. A dialog is
  right on a page and wrong everywhere this runs — a handheld, an API call, a job queue — so the rule is
  applied and the dialog is not.
- **A job with no location yet is checked against any location.** Somebody who is a warehouse employee
  nowhere is the wrong person however the job ends up; which location it turns out to be is checked when
  the job names one.

The check runs on `Assigned To User ID`, which is the one gate every path goes through — the task list,
the handheld and `Assign` all validate that field. Clearing the field is not a person, so it is not
checked.

## Holding the document

Writing back fills in what was handled; it never stopped anybody posting the document anyway. A receipt
could be posted while three of its put-aways were still on the floor, and what Business Central then
believed had been received was whatever happened to be on the document at that moment.

`Open Work On Posting` decides what happens. It ships as **Let the document be posted** — the behaviour
the app has always had — and the other value holds the document until every job raised from it has been
finished or cancelled.

Three things about how it is built:

- **It is a subscriber, and the first one this app has on a warehouse publisher.** Everything else this
  app does inside standard Business Central is a button. Posting is different: there is no moment a user
  could be asked to press something, and a guard that has to be remembered is not a guard.
- **The subscriber body is one line.** `Whse.-Post Receipt` and `Whse.-Post Shipment` both publish
  `OnBeforeRun` with the document line, and each subscriber hands the document straight to
  `WHA Open Work Mgt.`, which resolves the policy from setup. Neither subscriber knows what any policy
  does, which is what the polymorphic rule asks for.
- **A cancelled job is an answer.** Only a job nobody has finished *or* cancelled holds the document;
  somebody deciding the work is not needed releases it as surely as doing it.

What it does not do: nothing warns while the work is still open, so the first anybody hears about it is
the refusal at posting. And the whole thing is off unless the feature is enabled — a company not running
directed work is never held up by a queue it does not use.

## Item tracking on a job

`Lot No.` and `Serial No.` sit next to the item on the task. Until they existed, a directed pick of a
tracked item could not say what it picked — which broke traceability, and would have broken posting
the moment anything downstream tried to adjust from a job.

Three ways they get filled in, and one that is deliberately missing:

- **From the pallet, when the pallet leaves no doubt.** A job naming a handling unit that holds
  exactly one line for the item takes that line's lot and serial. That is reading a fact, not
  guessing. A pallet holding two lots of one item fills in nothing, which is the case where guessing
  would be wrong and the case bin content has always been wrong about.
- **From the partner system.** A task request may name `lotNumber` and `serialNumber`, so an upstream
  system can ask for one lot out of a pallet it believes holds several. **What the request asked for
  wins over what the pallet says** — whoever raised the work may know something the pallet does not.
- **By hand**, on the job card.
- **Not by the operator.** Nothing on the handheld asks them to scan a lot. Adding a step to the flow
  is an operator-review question before it is a build item, and the review has still not happened.
  Until it does, an item job with no pallet behind it is confirmed without proving what was picked —
  the same gap the capability register records.

The warehouse document sources fill in neither, and that is not laziness: tracking on a receipt or
shipment line lives in reservation entries rather than on the line, and picking one out to put on a
job would be a guess about which of them the warehouse will actually move.

## Not done

- **Task interleaving by type and travel path.** `GetNextForUser` ranks by priority and due date, and
  returns an operator's own work first. It does not sequence a pick and a put-away into one trip, and
  it does not know the physical layout of the warehouse. Travel-path sequencing needs a bin
  coordinate or zone-ordering model that does not exist yet.
- ~~**Nothing holds a document open while jobs against it are outstanding.**~~ **Closed, behind a
  setting that ships off.** See *Holding the document* below.
- ~~**The link runs one way only.**~~ **Closed, behind a switch** — see *Writing back* above. What
  remains true: **nothing stops the document being posted while jobs against it are still open.**
  Writing back fills in what was handled; it does not hold the document, and a warehouse that wants
  posting blocked until the floor is finished needs something this app does not have.
- ~~**Only two kinds of document.**~~ **The movement worksheet is now a third**, and the other
  candidates turn out to be **unreachable rather than unbuilt**: internal put-away, internal pick and
  warehouse picks for production or assembly all test the location for `Require Put-away`,
  `Require Pick` or `Directed Put-away and Pick` before they will exist, and this app refuses to raise
  work at any such location. Adding them would be code that can never run. Transfer orders need no
  source of their own — they flow through a warehouse receipt and shipment. See
  [../location-configuration.md](../location-configuration.md).
- **Nothing revisits work already assigned.** Turning the restriction on leaves jobs already held by
  somebody who is not a warehouse employee exactly where they are, and they can still be started and
  finished. Only a new assignment is checked.
- **The guard only covers the document sources.** Work typed in by hand names its own location and is
  not checked, and a location whose flags change after work was raised leaves that work standing.
- **Nothing acts on a stale job.** `SourceIsOpen` can tell that the line behind a task has been dealt
  with elsewhere, and nothing cancels, warns or filters on that answer.
- **Bins are half-filled by design.** A generated put-away knows where to start and not where to
  finish; a generated pick knows the reverse. See the section above — that half belongs to slotting.
- **The source model is still a guess.** It assumes this customer receives through warehouse receipts
  and ships through warehouse shipments. That is the standard shape, and it is not a signed-off fact;
  Phase 0 is what would make it one. The guess is isolated in three codeunits behind an extensible
  enum, so replacing it is a codeunit and an enum value, exactly as `FEAT-INT-001` isolated its
  payload shapes.
- **Task history.** See the data model note above — deliberate.
- **Over-picking.** A job can be closed with less than was asked for, never with more. Finding
  fourteen where twelve were wanted is a different conversation, and nobody has had it yet.
- **No inventory effect.** `Quantity Handled` records what an operator moved; it posts nothing to the
  *item* ledger. Since segment 6 it does move stock between bins where the setting asks for it, which
  is a warehouse-entry effect and not a ledger one. What a short pick should do to stock is still a
  question for the capability register.
- **The handling unit and the bin are two records kept in step by ordering.** Registration does not
  derive the unit's position from bin content, nor the reverse. Making one the source of the other is
  a larger change and reaches the handling unit's own model.
- **Handheld presentation.** `FEAT-RF-001` is the scanner-shaped view of this queue.
- **Getting-started in the customer language** — the language has not been confirmed.
