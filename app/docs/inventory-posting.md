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

- **Directed put-away and pick locations are untested and probably do not work.** Posting an item
  journal line at a location with directed put-away and pick requires a warehouse journal as well;
  the check refuses the line otherwise. Nothing in this module raises one. Its sibling module now
  does raise warehouse journal lines — see [warehouse-registration.md](warehouse-registration.md) —
  but for *movements*, not for the adjustment through the adjustment bin that this gap needs. Closing
  it is the obvious next piece of the same argument.
- **Item tracking is carried, not created.** A lot number reaches the ledger entry, but no reservation
  entry or tracking specification is built. An item whose tracking code demands specific handling will
  be refused by the posting check, and the count sheet will not close.
- **No dimensions beyond the item's own defaults.** Nothing sets a dimension from the location, the
  count sheet or the hold.
- **Costs are not touched.** A positive adjustment posts at the item's cost; nothing lets a count
  state what the goods were worth.
- **No reversal.** A count sheet cannot be reopened and a hold cannot be un-released, so a posting made
  in error is corrected in Business Central, not here.
