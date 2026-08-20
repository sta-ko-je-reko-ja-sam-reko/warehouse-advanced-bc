# FEAT-CNT-001 - Counting

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Standard Business Central has a physical inventory journal and a warehouse physical inventory, so
> the gap this feature claims is *perpetual counting while the warehouse keeps working* — blind
> counts, a tolerance, and an approval before a difference is accepted. Whether the customer needs
> that, or just the standard journal, is a Phase 0 question.

## Business process

A stocktake stops the warehouse. Cycle counting does not: a slice of the warehouse is counted while
the rest of it works, and the count is compared with what the system believed at the moment the count
was ordered.

A **count sheet** is that slice:

1. A sheet is opened for a location, with a **selection** — what it gathers when it is filled — and a
   **blind** flag.
2. It is **filled**. Each line records what the system believes is there as the **expected quantity**.
3. It is **sent out to be counted**. From here the expected quantities are fixed.
4. Lines are counted. Each count works out a **difference** and decides whether that difference is
   bigger than the **tolerance** allows.
5. When every line has been counted, the sheet is **marked as counted**.
6. Every difference beyond the tolerance is **approved** by somebody, and the sheet is **closed**.
   Closing it is what turns a difference into an adjustment.

A sheet that is no longer wanted is **cancelled**, keeping whatever was counted.

### Delivered so far

**Segment 1** — the sheet and its lines, two selections, blind counting, the tolerance, the approval,
and the life cycle. Segment 1 did not adjust inventory.

**Segment 2** — adjusting: closing a sheet hands every difference to a posting method chosen in the
counting setup, and the sheet records what came back. Counting is no longer a measuring feature —
though it can still be configured as one, and that is the setting a new installation starts on.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Count Setup` | 50500 | Single-record feature setup, including how differences are posted |
| `WHA Count Sheet` | 50501 | One slice of the warehouse to count |
| `WHA Count Sheet Line` | 50502 | One thing to count, and what was found |

### `WHA Count Sheet`

| Field | Type | Notes |
|---|---|---|
| `No.` | `Code[20]` | Primary key, from this feature's own number series |
| `Description` | `Text[100]` | The aisle or the round the sheet covers |
| `Location Code` | `Code[10]` | The location being counted. **Required before filling** |
| `Status` | `Enum "WHA Count Status"` | Open / Counting / Counted / Closed / Cancelled. Not editable |
| `Selection` | `Enum "WHA Count Selection"` | What the sheet gathers when it is filled |
| `Blind` | `Boolean` | Whether the expected quantity is hidden from the counter |
| `Due Date`, `Assigned To User ID` | | Who should count it, and by when |
| `Posting Date` | `Date` | The date any adjustment posts under. Defaults to the work date when the sheet is created, editable until the sheet closes, and refused afterwards |
| `Started At` / `Counted At` / `Closed At` | `DateTime` | Stamped by the life cycle |
| `Posted`, `Posting Document No.`, `Posted At` | | What closing the sheet did about the ledger. `Posted` is true only when the ledger was actually written |
| `Line Count`, `Counted Line Count`, `Variance Line Count`, `Unapproved Variance Count` | `Integer` | FlowFields over the lines |

### `WHA Count Sheet Line`

| Field | Notes |
|---|---|
| `Sheet No.`, `Line No.` | Primary key |
| `Bin Code`, `Item No.`, `Variant Code`, `Unit of Measure Code`, `Handling Unit No.` | What is being counted |
| `Lot No.`, `Serial No.` | The tracking the goods carry. Filled by the handling unit selection; blank from the bin selection, which counts aggregated bin content |
| `Expected Quantity` | What the system believed when the sheet was filled. Not editable |
| `Counted Quantity` | What was found. **The only editable field on a line** |
| `Counted` | Set by entering a count. **A count of zero is a count** |
| `Variance` | Counted minus expected |
| `Out of Tolerance` | Whether the difference is bigger than the setup allows |
| `Approved`, `Approved By User ID` | Who accepted the difference |
| `Counted By User ID`, `Counted At` | Who counted it, and when |
| `Posting Quantity`, `Posted` | The signed adjustment the line handed over when the sheet closed, and whether it reached the ledger. Kept separately from `Variance`, which is whatever was counted last |

Entering `Counted Quantity` is what counts a line: the table field delegates to
`WHA Count Line Logic`, which works out the difference, decides the tolerance question, and stamps
who and when. There is no separate "record the count" action to forget, and the API, the page and any
future handheld screen all go through the same one line of logic.

### `WHA Count Setup`

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Default Selection` | What a new sheet gathers unless it says otherwise |
| `Count blind` | Ships **on** |
| `Tolerance Quantity` / `Tolerance Percent` | Ships as 0 and 2%. A line is within tolerance when it passes **either**, whichever is the more generous |
| `Approve differences above tolerance` | Ships **on**. Off closes sheets without an approval step |
| `Post differences by` | What closing a sheet does about the ledger. Ships as **Do not post** |
| `Item Journal Template Name` / `Item Journal Batch Name` | Where the lines go when they are staged rather than posted |
| `Posting Reason Code` | Put on every adjustment a count raises, so counting differences can be told apart in the ledger |

**The setup defaults are applied on insert, and win.** A new sheet takes `Selection` and `Blind` from
the setup whenever it was inserted with the enum's first value or with `Blind` false — which a Boolean
cannot distinguish from *deliberately not blind*. So a sheet created through the API with
`blind: false` while the setup says blind comes out blind. Untick **Count blind** on the sheet
afterwards; the field stays editable for exactly that reason. The same shape as `Strategy` on a wave,
and the same trade: one setting that always applies, rather than a second flag saying whether the
first one meant it.

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Count Setup` | table | 50500 | `app/src/Counting/tables/CountSetup.Table.al` |
| `WHA Count Sheet` | table | 50501 | `app/src/Counting/tables/CountSheet.Table.al` |
| `WHA Count Sheet Line` | table | 50502 | `app/src/Counting/tables/CountSheetLine.Table.al` |
| `WHA Count Status` | enum | 50500 | `app/src/Counting/enums/CountStatus.Enum.al` |
| `WHA Count Selection` | enum | 50501 | `app/src/Counting/enums/CountSelection.Enum.al` |
| `WHA ICountSheet` | interface | — | `app/src/Counting/interfaces/ICountSheet.Interface.al` |
| `WHA ICountSheetLine` | interface | — | `app/src/Counting/interfaces/ICountSheetLine.Interface.al` |
| `WHA ICountSelection` | interface | — | `app/src/Counting/interfaces/ICountSelection.Interface.al` |
| `WHA Count Sheet Logic` | codeunit | 50500 | `app/src/Counting/codeunits/CountSheetLogic.Codeunit.al` |
| `WHA Count Line Logic` | codeunit | 50501 | `app/src/Counting/codeunits/CountLineLogic.Codeunit.al` |
| `WHA Count Feature Setup` | codeunit | 50502 | `app/src/Counting/codeunits/CountFeatureSetup.Codeunit.al` |
| `WHA Count App Area Sub.` | codeunit | 50503 | `app/src/Counting/codeunits/CountAppAreaSub.Codeunit.al` |
| `WHA Demo Count` | codeunit | 50504 | `app/src/Counting/codeunits/DemoCount.Codeunit.al` |
| `WHA Count Bin Selection` | codeunit | 50505 | `app/src/Counting/codeunits/CountBinSelection.Codeunit.al` |
| `WHA Count HU Selection` | codeunit | 50506 | `app/src/Counting/codeunits/CountHUSelection.Codeunit.al` |
| `WHA Count Bin Lot Selection` | codeunit | 50509 | `app/src/Counting/codeunits/CountBinLotSelection.Codeunit.al` |
| `WHA Whse Stock By Lot` | query | 50509 | `app/src/Counting/queries/WhseStockByLot.Query.al` |
| `WHA Count Posting` | codeunit | 50507 | `app/src/Counting/codeunits/CountPosting.Codeunit.al` |
| `WHA Count Appl. Area Setup` | tableextension | 50500 | `app/src/Counting/tableextensions/CountApplAreaSetup.TableExt.al` |
| `WHA Count Setup` | page | 50500 | `app/src/Counting/pages/CountSetup.Page.al` |
| `WHA Count Sheets` | page | 50501 | `app/src/Counting/pages/CountSheets.Page.al` |
| `WHA Count Sheet Card` | page | 50502 | `app/src/Counting/pages/CountSheetCard.Page.al` |
| `WHA Count Sheet Subform` | page | 50503 | `app/src/Counting/pages/CountSheetSubform.Page.al` |
| `WHA API Count Sheet` | page | 50504 | `app/src/Counting/pages/APICountSheet.Page.al` |
| `WHA API Count Sheet Line` | page | 50505 | `app/src/Counting/pages/APICountSheetLine.Page.al` |
| `WHA API Demo Count` | page | 50506 | `app/src/Counting/pages/APIDemoCount.Page.al` |
| `WHA Counting Tests` | codeunit | 51008 | `test/src/codeunits/CountingTests.Codeunit.al` |
| `WHA Count Activities Cue` | tableextension | 50501 | `app/src/Counting/tableextensions/CountActivitiesCue.TableExt.al` |
| `WHA Count Activity Provider` | enumextension | 50501 | `app/src/Counting/enumextensions/CountActivityProvider.EnumExt.al` |
| `WHA Count Activity Cues` | codeunit | 50508 | `app/src/Counting/codeunits/CountActivityCues.Codeunit.al` |
| `WHA Count Activities` | pageextension | 50501 | `app/src/Counting/pageextensions/CountActivities.PageExt.al` |

All in namespace `WarehouseAdvanced.Counting`, from the reserved block `50500..50549`. Core gained a
`WHA Feature` enum value; the count sheet numbering lives on this feature's own setup.

Segment 2 added one codeunit here and nothing else new: the posting engine itself is shared, lives in
`app/src/Posting/`, and is described in [../inventory-posting.md](../inventory-posting.md).

## Selections — what a sheet counts

`WHA ICountSelection` has `Fill`, which adds the lines, and `Describe`, which says in one line what it
gathers.

**This differs deliberately from a wave strategy.** A wave strategy is a filter and a sort and never
loops, because every candidate is the same kind of record. A count selection is not: the two that ship
produce different shapes of line — one per item in a bin, one per handling unit line — so a filter
cannot express the choice. What a selection is *not* allowed to do is write the line itself: it calls
`AddLine` on the sheet logic, which owns the guard that a sheet can only be filled while it is open.

Three ship:

- **Bins** (default) — every item Business Central believes is in a bin at the location. A bin content
  of zero is still counted: a bin the system thinks is empty is worth confirming, and one that turns
  out not to be is exactly the finding a count exists for.
- **Handling units** — every line of every unit standing at the location, with the unit number on the
  line. This is what a licence-plate warehouse counts: not what is in the bin, but whether the pallet
  holds what its label claims.
- **Bins by lot** — the same bins, split by lot and serial number. It reads **warehouse entries**
  rather than bin content, because bin content aggregates across lots: it can say a bin holds 40 but
  never that the 40 is 25 of one lot and 15 of another. This is the selection a warehouse with tracked
  items has to use, and the reason is in *Adjusting* below — a difference with no lot on it cannot be
  posted.

  It differs from the bins selection in one way worth knowing: **a lot that nets to zero is left off
  the sheet.** Bin content is a record that persists at zero and is worth confirming; a lot that came
  and went is not in the bin at all, and listing every lot that ever passed through would bury the
  count in rows nobody claims are there.

`WHA Count Selection` is extensible, so ABC velocity, "bins not counted since", or by-zone is an
`enumextension` value and one codeunit.

## Blind counting

A counter who can see the expected number tends to write it down. When a sheet is blind, the expected
quantity and the difference are **hidden on the lines** until the sheet reaches *Counted* — then they
appear, because the person reviewing differences needs both.

This is a page-level rule, not a data rule: `WHA Count Sheet Card` tells its subform whether to show
the columns. An API caller can always read `expectedQuantity`, which is the right trade — the
integration that feeds counts in from a device is not the person doing the counting.

## Tolerance and approval

A line is **within tolerance** when the absolute difference is no more than the more generous of the
two allowances: the flat `Tolerance Quantity`, or `Tolerance Percent` of the expected quantity. Both
zero means any difference at all is out of tolerance.

Out-of-tolerance lines have to be approved before the sheet can be closed — unless
`Approve differences above tolerance` is switched off.

**Counting a line again withdraws its approval.** An approval is an approval of a number, and a
recount is a different number.

## What survives

A sheet that has been **counted or closed** cannot be deleted, and neither can one that carries a count
on any of its lines — including a **cancelled** one. Cancelling is how a sheet is withdrawn while
keeping what was found; without the second guard, cancel-then-delete would be the way round the first.
An open sheet nobody has counted is a draft, and deleting it takes its lines with it.

## Completion is asked for, not pushed

As with waves, nothing pushes a finished line back to its sheet. `CompleteIfCounted` marks a sheet
counted when every line has been, and does nothing otherwise; it is called from **Mark fully counted
sheets** on the sheet list and is safe to run from a job queue. A sheet's status can therefore lag
behind reality, while the FlowField counts are always current.

## Adjusting — what closing a sheet does

Closing a counted sheet is the moment a difference stops being an observation and becomes an
adjustment. `WHA Count Sheet Logic.Close` therefore does the approval check, then calls
`WHA Count Posting.PostDifferences`, then sets the status — in that order, so a sheet whose adjustment
cannot be posted does not close. A closed sheet that adjusted nothing is the state this segment exists
to remove; it would be perverse to reintroduce it as an error path.

`PostDifferences` builds one posting request line per line with a non-zero difference:

- **More found than expected** becomes a positive adjustment of the difference.
- **Less found than expected** becomes a negative adjustment of the difference.
- **A line that matched** produces nothing. A count sheet that agrees with the system posts no
  document at all, which is the ordinary outcome and should leave no trace in the ledger.

Every line carries the sheet's location, the line's bin, its lot or serial number, the sheet's
`Posting Date`, and the **sheet's own number as the document number** — so a ledger entry always names
the count that caused it, and no second number series was invented to do it.

What the posting method then does is its business, not the sheet's. See
[../inventory-posting.md](../inventory-posting.md) for the three that ship. What comes back is written
onto the sheet (`Posted`, `Posting Document No.`, `Posted At`) and onto each line (`Posting Quantity`,
`Posted`).

**`Posted` on the sheet means the item ledger was written.** A sheet closed with the *journal lines*
method has a posting document and a posting time and is **not** marked posted, because the lines are
sitting in a journal waiting for somebody. Reading that field as "closing finished" would be wrong in
exactly the configuration a cautious warehouse is most likely to run.

### The posting date

`Posting Date` is set on the sheet, not derived at close time. A count is a statement about a moment,
and the moment is rarely the moment somebody gets round to closing the paperwork. It defaults to the
work date when the sheet is created and can be corrected while the sheet is open or being counted;
once the sheet is closed the field refuses to move, because the date a difference was posted under is
part of what was posted.

### Tracking on a count line

`Lot No.` and `Serial No.` on the count sheet line are new in this segment, and they exist for
posting: without them, a difference on a tracked item cannot be adjusted at all. The handling unit
selection fills them from the unit's own lines through `SetLineDetails`, which also carries the
description across — one call where segment 1 had a local that only did the description.

The bins selection leaves them blank, and correctly: bin content is aggregated across lots, so there
is no single lot to name.

~~Counting a tracked item by bin therefore still cannot be posted.~~ **The bins-by-lot selection
closes this.** It reads warehouse entries and groups by bin, item, variant, unit of measure, lot and
serial, so every line it makes carries the lot the adjustment needs. The bins selection is unchanged
and still cannot post a tracked item — that is now a choice between two selections rather than a hole,
and the selection's own `Describe` text says which to use.

## Role centre activities

This feature contributes its own tiles to the warehouse role centre: **count sheets on the floor and counts waiting for approval**. Four objects do it,
all of them in this feature's own folder — a `tableextension` adding the cue fields, an `enumextension`
registering the provider, a codeunit that counts, and a `pageextension` that puts the fields on the cue
part and writes the returned counts back.

**The foundation names none of them.** The seam, and why it is shaped this way, is in
[../FEAT-CORE-001-Foundation/technical-documentation.md](../FEAT-CORE-001-Foundation/technical-documentation.md).

The count runs in a read-only background session and its first line asks whether this feature is
switched on. A switched-off feature adds **nothing** rather than a zero, so its tiles never appear.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHACounting` bound to
`WHA Count Feature Setup` (guided setup step 100); `Application Area Setup` gained `WHA Counting`
through this feature's own tableextension; the setup page is `ApplicationArea = All` while the count
pages carry `WHACounting`. Every API write path and bound action calls `CheckEnabled`.

**The count sheet number series lives on this feature's own setup**
(`WHA Count Setup."Count Sheet Nos."`), with the feature's own application area, and this feature's
guided-setup step creates `WHA-COUNT` when numbering is asked for. The foundation neither creates it
nor checks it.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Counting` | `counting` | `WHA API Count Sheet` | read, create, modify, and run fill / start / complete / close / cancel |
| `Warehouse Advanced - Counting` | `counting` | `WHA API Count Sheet Line` | **read only** |
| `Warehouse Advanced - Demo Counting` | `demoCounting` | `WHA API Demo Count` | run `importDemoData` only |

The line tool is read-only **on purpose**. An agent may plan a count, send it out, and report what
came back; it may not enter a count or approve a difference. Both of those are claims about physical
stock made by a person standing in front of it, and an approval is an accountability. The API page
itself allows the write, so a handheld or an interface can push counts in — the restriction is on the
agent, not on the entity.

## Demo data

`WHA Demo Count` seeds three sheets under fixed numbers `DEMO-COUNT-001..003`: one filled from the
bins at a location, one filled from the handling units standing there and part-counted with a
difference on it, and one blind sheet that has not been started. It prefers a location that already
has handling units, so the second sheet is not empty on a company that ran the handling unit sample
data first. `Import()` also builds the `WHA-COUNT` RapidStart package.

## Tests

`WHA Counting Tests` (codeunit 51008), 23 tests.

**Segment 1**, 16 tests: filling from handling units takes what each unit says it holds, with the bin
it is standing in; a count that matches leaves no difference; a count of nothing is still a count and
is flagged; a difference inside the percentage allowance is not flagged while one beyond the flat
allowance is; nothing can be counted before the sheet goes out; a sheet with lines still uncounted
cannot be marked counted and is marked when its last line is counted; a sheet waits for its
differences to be approved and closes once they are; counting a line again withdraws its approval; a
line within tolerance cannot be approved; an empty sheet cannot be sent out; a counted sheet cannot be
deleted while an open one takes its lines with it; a cancelled sheet that carries a count cannot be
deleted either; and demo idempotency.

**Segment 2**, 7 tests: closing a sheet hands every difference to the posting method, as an adjustment
the size of the difference under the sheet's own number at the sheet's location; finding more than
expected goes the other way; a sheet that found no difference hands over nothing and is not marked
posted; a posted sheet keeps the signed adjustment on each line separately from the difference; a sheet
set to post nothing still closes and says plainly that nothing reached the ledger; filling from
handling units carries the lot onto the count line; and the posting date cannot be moved once the sheet
is closed.

Those seven run against `WHA Test Posting Recorder`, an implementation of the posting interface bound
to its own value of `WHA Posting Method` through an `enumextension` in the test project. It answers
`true` to `WritesToLedger()` and keeps everything it is handed, so what counting *asks the ledger for*
is asserted exactly, with no items, posting groups or open period needed. It is also the extensibility
claim being exercised rather than asserted: a dependent app plugs a posting method in the same way.

Two things stay out of the automated suite and belong in the integration test plan:

- The **bins** selection needs posted warehouse entries to be worth asserting on; the automated tests
  use the handling unit selection and hand-added lines.
- **Whether `Item Jnl.-Post Line` accepts the line** — the actual ledger write. It needs a company with
  items and, per `CLAUDE.md`, a W1 container rather than the US one this project develops against.

## Not done

- ~~**A tracked item counted by bin cannot be posted.**~~ **Delivered** — *Bins by lot* is the third
  selection this entry asked for. Two things it did not settle: **package numbers** are not read, so a
  warehouse tracking by package has the same problem one level down; and nothing *stops* somebody
  choosing the bins selection for a tracked item, because whether that is a mistake depends on
  what they are counting.
- **Nothing has been posted for real.** The posting path is covered by unit tests against a recorder
  and by nothing else: no ledger entry has ever been written by this code. See
  [../inventory-posting.md](../inventory-posting.md) for what that leaves untested. Directed put-away
  and pick locations are now **handled** — the bins are adjusted separately from the ledger, as such a
  location requires — but handled is not the same as proven, and none of it has run against one.
- **No dimensions, and no cost on a positive adjustment.** An adjustment carries the item's own
  defaults and nothing from the count, the location or the sheet.
- **A closed sheet cannot be reopened.** A posting made in error is corrected in Business Central, not
  by unwinding the sheet.
- **No ABC or velocity-driven selection.** The catalogue names perpetual counting "by ABC/trigger".
  What ships is two selections that gather everything at a location; nothing decides *which* slice is
  due to be counted, so the choice of slice is currently a person's.
- **No counting on the handheld.** Counts are entered on the sheet at a desk. A count sheet on the
  scanner is the obvious next segment, and it is an operator-review question first.
- **No recount round.** A difference is approved or it is not; there is no "count it again and use the
  second number" step that many warehouses run before approving.
- **Getting-started in the customer language** — the language has not been confirmed.
