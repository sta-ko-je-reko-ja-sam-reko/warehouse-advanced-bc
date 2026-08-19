# FEAT-TASK-001 - Directed Work

## Source/legacy reference

N/A (greenfield).

> **Scope note.** This feature was built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> The Qguar capability discovery (Phase 0) has not been run. Directed work was chosen as the first
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
| `Assigned To User ID` | `Code[50]` | `TableRelation = User."User Name"`. Clearing it returns the task to the queue |
| `Assigned At` / `Started At` / `Completed At` | `DateTime` | Stamped by the life cycle, not editable |

Keys: `PK` on `No.` (clustered), plus `Queue` (`Status`, `Location Code`, `Priority`, `Due Date`),
`Assignment` (`Assigned To User ID`, `Status`, `Priority`), and `HandlingUnit` (`Handling Unit No.`).

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
| `WHA Task Appl. Area Setup` | tableextension | 50200 | `app/src/DirectedWork/tableextensions/TaskApplAreaSetup.TableExt.al` |
| `WHA Warehouse Task Setup` | page | 50200 | `app/src/DirectedWork/pages/WarehouseTaskSetup.Page.al` |
| `WHA Warehouse Task Card` | page | 50201 | `app/src/DirectedWork/pages/WarehouseTaskCard.Page.al` |
| `WHA Warehouse Tasks` | page | 50202 | `app/src/DirectedWork/pages/WarehouseTasks.Page.al` |
| `WHA API Warehouse Task` | page | 50203 | `app/src/DirectedWork/pages/APIWarehouseTask.Page.al` |
| `WHA API Demo Warehouse Task` | page | 50204 | `app/src/DirectedWork/pages/APIDemoWarehouseTask.Page.al` |
| `WHA Warehouse Task Tests` | codeunit | 51001 | `test/src/codeunits/WarehouseTaskTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.DirectedWork`, from the reserved block `50200..50249`.

Core objects changed in the same pass: `WHA Feature` gained a value. Numbering was originally added
to Core as well; it has since moved to this feature's own setup, so Core no longer knows this feature
numbers anything.

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
| `NothingFoundAtAllStillClosesTheJob` | An empty bin is an answer, not a hand back |
| `DemoImportIsIdempotent` / `DemoImportCoversEveryTaskType` | The seeder is safe to re-run and covers the enum |

## Not done

- **Task interleaving by type and travel path.** `GetNextForUser` ranks by priority and due date, and
  returns an operator's own work first. It does not sequence a pick and a put-away into one trip, and
  it does not know the physical layout of the warehouse. Travel-path sequencing needs a bin
  coordinate or zone-ordering model that does not exist yet.
- **A link to the source document.** A task is not yet tied to a warehouse receipt, shipment or
  worksheet line, so nothing generates tasks from standard warehouse activity. That is the segment
  that turns this from a queue into an execution layer, and it should be designed against what the
  capability register says the customer actually receives and ships.
- **Task history.** See the data model note above — deliberate.
- **Over-picking.** A job can be closed with less than was asked for, never with more. Finding
  fourteen where twelve were wanted is a different conversation, and nobody has had it yet.
- **No inventory effect.** `Quantity Handled` records what an operator moved; it posts nothing. What
  a short pick should do to stock is a question for the capability register.
- **Handheld presentation.** `FEAT-RF-001` is the scanner-shaped view of this queue.
- **Getting-started in the customer language** — the language has not been confirmed.
