# Inventory posting

How Warehouse Advanced changes what Business Central believes is in stock. This is not a feature
document — nothing here is switched on, has a wizard step, or appears in the guided setup list. It
describes the one piece of shared machinery that two features call, and the reasoning that put it
there rather than inside either of them.

## Why it is shared

Counting and quality hold both shipped a first segment that stopped at the same line. A closed count
sheet recorded a difference and adjusted nothing; a scrapped pallet was taken out of use and written
off nowhere. Both needed the item journal, both needed the same decisions about posting dates,
documents and item tracking, and both would have needed the same argument with the customer about
whether the warehouse app may touch the ledger at all.

Building that twice would have produced two half-answers that drifted apart. It is built once, in
`app/src/Posting/`, and each feature decides only *whether* and *how* to use it.

## Why it is not a feature

`feature-ready.md` makes a feature expensive on purpose: a setup table, an `Enabled` toggle, a
dedicated application area, a wizard step, demo data, an MCP configuration, a RapidStart package.
Posting earns none of those:

- **Nothing to switch on.** A warehouse does not turn posting on; it turns *counting* on and then
  decides what closing a sheet should do. A second toggle would only create a state where counting is
  on, posting is off, and the count sheet page cannot explain itself.
- **Nothing to configure centrally.** The journal batch a count adjustment goes to is not necessarily
  the one a scrap write-off goes to, and the reason code certainly is not. Those settings belong to
  the feature raising the posting, and that is where they live.
- **Nothing to show.** There is no posting list, no posting card, no posting API. What was posted is
  read on the count sheet and on the hold, next to what caused it.

So the module carries an interface, three implementations, a buffer table and a small facade, and
appears in the permission sets like anything else. It is a library, and the documentation says so
rather than leaving the next reader to infer it from the absence of a setup page.

## The buffer

`WHA Posting Request` (table 50750, `TableType = Temporary`) is what a feature hands over. One row is
one line of stock to add or remove:

| Field | Purpose |
|---|---|
| `Entry No.` | Position within the request |
| `Posting Type` | `WHAPositiveAdjustment` or `WHANegativeAdjustment`. **Extensible** |
| `Item No.`, `Variant Code`, `Unit of Measure Code`, `Quantity` | What and how much. The quantity is **always positive**; direction lives in the type |
| `Location Code`, `Bin Code` | Where |
| `Lot No.`, `Serial No.` | Item tracking, carried straight onto the journal line |
| `Posting Date`, `Document No.`, `Description`, `Reason Code` | What the ledger entry will say |
| `Journal Template Name`, `Journal Batch Name` | Where the line goes when it is staged rather than posted |
| `Source Table No.`, `Source No.`, `Source Line No.` | What raised it, so the result can be written back against the right line |
| `Posted`, `Journal Line No.` | Filled in by the implementation: what actually happened to this line |

**The buffer is the decoupling.** Without it the posting interface would have to take a count sheet
line or a handling unit, and the shared module would know about both features. With it, the module
knows about neither, and a third feature that needs to post writes no new posting code at all.

It is also what makes posting testable without a ledger. Every procedure takes the buffer as a `var`
parameter, so an implementation that simply keeps what it was handed is a complete implementation —
which is exactly what the test project supplies. See *Testing*, below.

## The three ways of posting

`WHA Posting Method` (enum 50751) is extensible and binds each value to its own implementation of
`WHA IInvtPosting`:

| Value | Implementation | What it does |
|---|---|---|
| `WHANone` | `WHA No Invt. Posting` | Takes nothing. The app keeps its own record; Business Central is left believing what it believed |
| `WHAJournalLines` | `WHA Jnl. Line Posting` | Writes item journal lines into the configured batch and posts nothing. Somebody opens the journal, looks at what the warehouse found, and posts it |
| `WHAPostDirect` | `WHA Direct Posting` | Builds the journal line, posts it through `Item Jnl.-Post Line`, and keeps nothing. There is no batch left holding a line somebody could post twice |

The interface is three methods:

```al
procedure Post(var PostingRequest: Record "WHA Posting Request"): Integer;
procedure Describe(): Text;
procedure WritesToLedger(): Boolean;
```

`WritesToLedger()` is the one that earns its place. A journal line is a proposal, not a posting, so a
count sheet closed under `WHAJournalLines` records a posting document and a posting time but is **not
marked posted**. Collapsing those two states into one boolean would have made the sheet claim
something untrue in exactly the configuration a cautious customer is most likely to choose.

`Describe()` is shown on both setup pages, under the method field, so the choice is made with its
consequence in view rather than from a caption.

**`WHANone` is value 0 on purpose.** An existing installation upgrading into this segment gets the
new field at its default, and nothing that used to record a difference silently starts writing to the
ledger. Turning posting on is a decision somebody makes, with a date on it.

### Extending it

A dependent app adds an `enumextension` value with its own implementation — a posting method that
routes through a different journal, or one that raises a workflow instead. Nothing in counting or
quality hold changes, no event is subscribed to, and the two features never learn the new value
exists. The test project does exactly this (`WHA Test Posting Method`), which is the extensibility
claim being exercised rather than asserted.

## Building the journal line

`WHA Posting Mgt.BuildJournalLine` turns one request row into an `Item Journal Line`, and both
implementations that touch a journal call it, so the two cannot drift apart. Three details are worth
knowing:

- **No journal template or batch is required to post directly.** `Item Jnl.-Post Line` does not need
  one, and using one would leave rows in a batch that somebody could post a second time. The template
  and batch fields exist for `WHAJournalLines`, which does need somewhere to put the line.
- **`Gen. Prod. Posting Group` comes from validating `Item No.`** — it is the one field the posting
  check insists on beyond the item, quantity, posting date and document number.
- **Lot and serial numbers are assigned, not validated.** Validating `Lot No.` on an item journal line
  outside a batch runs `CheckItemTracking`, which clears the tracking when the batch does not have
  item tracking switched on. Assigning it directly leaves it in place, and
  `ItemLedgEntry.CopyTrackingFromItemJnlLine` carries it onto the ledger entry.

## Tracking, checked before it is handed over

The app knows which item it is posting and can read that item's tracking code, so it refuses a line
Business Central is going to refuse — in its own words, at the moment the sheet is closed or the hold
released, rather than as an error about a journal line nobody can see.

Three things are checked, and only when the chosen method **writes to the ledger**. A warehouse that has
decided to record a count and correct it by hand has not asked the app to have an opinion about lot
numbers.

| Refused | Because |
|---|---|
| A lot-tracked item with no lot | `Item Jnl.-Post Line` requires one and will not post without it |
| A serial-tracked item with no serial number | The same |
| A serial number with a quantity other than one | A serial number names one unit. Business Central enforces this when the field is *validated*; this module assigns it, so nothing would have caught it |
| Stock added to a bin at a directed location, for an item dated by hand, under a lot Business Central has never seen | `Whse. Jnl.-Register Line` tests the expiry date on a positive warehouse entry. The app records no expiry, so if Business Central holds none either there is no honest date to supply |

The requirement is worked out with Business Central's own `Item Tracking Management.GetItemTrackingSetup`,
given the entry type and direction the line will be posted under — so the answer here and the answer at
posting are the same answer rather than two guesses that agree most of the time.

## Directed locations — where posting is two halves

At a location with **directed put-away and pick**, an item journal line carries **no bin code at all**.
Bins there live in warehouse entries alone, and the item ledger holds only the location. So posting a
count difference or a write-off at such a location is two writes, not one:

1. **The warehouse half.** A warehouse journal line — `Positive Adjmt.` into the bin, or
   `Negative Adjmt.` out of it — registered through `Whse. Jnl.-Register Line`, the base application's
   own registering codeunit. This is what moves bin content.
2. **The ledger half.** The item journal line, with no bin code and `Warehouse Adjustment` set, which
   is exactly the shape *Calculate Whse. Adjustment* produces.

`WHA Posting Mgt.` decides which shape to build by asking
`WHA Whse. Reg. Mgt.LocationIsDirected`, and `WHA Direct Posting` writes the warehouse half first.
Both halves are one operation: if the ledger refuses the line, the warehouse entry rolls back with it.

**Nothing is written to the location's adjustment bin, and that is the important part.** Business
Central uses that bin to hold the difference between a warehouse that has been adjusted and a ledger
that has not; *Calculate Whse. Adjustment* turns whatever stands in it into item journal lines. Because
this module writes both halves, that difference is zero. Leaving a counterpart entry in the adjustment
bin would look like an outstanding discrepancy and be posted a second time by whoever ran that report
next.

**`WHA Jnl. Line Posting` does neither half at a directed location** — it writes the journal line, with
no bin and the `Warehouse Adjustment` marker, and leaves it. That is deliberate and consistent with what
that method means: nothing has happened yet. Whoever posts the line owns the warehouse half, through the
Whse. Item Journal, exactly as they would for a line they typed themselves.

## Who calls it

| Feature | When | What it posts | Document number |
|---|---|---|---|
| `FEAT-CNT-001` counting | Closing a count sheet | One line per line that differs — positive where more was found, negative where less | The count sheet's own number |
| `FEAT-QC-001` quality hold | Releasing a hold with a decision that ends the goods | One negative line per thing the held handling unit was carrying | `QH` followed by the hold entry number |

Both stop the whole operation if posting fails. A count sheet whose adjustment cannot be posted does
not close, and a hold whose write-off cannot be posted is not released — the alternative is a closed
sheet that adjusted nothing, which is the state this segment exists to remove.

## Testing

Posting is the part of this app that most needs a real company and least has one. The split is
deliberate:

- **What a feature would post** is a unit test. Both features build the request into a temporary buffer
  and hand it to whatever implementation setup names, so a test names one that keeps what it is given
  and asserts the direction, the quantity, the document and the location without a single ledger
  entry.
- **What the ledger does with it** is an integration test, and it is **not written**. It needs items,
  posting groups, an open period and — per `CLAUDE.md` — a W1 container rather than the US one this
  project develops against.

The test project bridges the two with `WHA Test Posting Recorder`, a `SingleInstance` implementation
bound to its own enum value. It answers `true` to `WritesToLedger()`, so the features under test take
the branch a real posting takes, and it keeps everything it was handed so a test can assert on it.
That covers every decision the features make. It covers nothing about whether `Item Jnl.-Post Line`
accepts the line.

## Known gaps

- ~~**Directed put-away and pick locations are untested and probably do not work.**~~ **Handled — see
  *Directed locations* above.** What remains true is the second half of that sentence: it has never
  been run against one.
- **Item tracking is carried, not created, and that turns out to be enough.** ~~An item whose tracking
  code demands specific handling will be refused by the posting check.~~ **That was wrong**, and it was
  repeated in two feature documents before anybody read the base application: `Item Jnl.-Post Line`
  checks the **line's own** `Lot No.` and `Serial No.` fields, which this module sets, and the warehouse
  journal check falls back to the line's quantity against lot-filtered bin content when there is no
  warehouse tracking line. Both callers already raise **one request line per lot or serial** — a count
  sheet line, a handling unit line — which is exactly the shape that needs no reservation entry to
  split it.

  What is genuinely absent: nothing builds a reservation entry or tracking specification, so a **single**
  request line covering more than one lot cannot be posted. Nothing raises one today.
- **The directed path has never been run.** Every branch of it was written from the base application's
  own source — `Calculate Whse. Adjustment` for the journal line's shape, `WMS Management` for what the
  warehouse journal check requires — and none of it has touched a real WMS location. That needs zones,
  bin types, an adjustment bin and bin content to take from.
- **No dimensions beyond the item's own defaults.** Nothing sets a dimension from the location, the
  count sheet or the hold.
- **Costs are not touched.** A positive adjustment posts at the item's cost; nothing lets a count
  state what the goods were worth.
- **No reversal.** A count sheet cannot be reopened and a hold cannot be un-released, so a posting made
  in error is corrected in Business Central, not here.
