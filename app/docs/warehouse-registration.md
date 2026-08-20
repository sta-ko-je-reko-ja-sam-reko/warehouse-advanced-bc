# Warehouse registration

How Warehouse Advanced tells Business Central where the goods went. This is not a feature document —
nothing here is switched on, has a wizard step, or appears in the guided setup list. It describes the
second piece of shared machinery in the app, alongside [inventory-posting.md](inventory-posting.md),
and the decision that put it there.

## The problem it exists to remove

Until this shipped, finishing a job moved the handling unit in the app's own records and **nothing
else**. `WHA Handling Unit` got a new `Bin Code`; Business Central's `Bin Content` and
`Warehouse Entry` still said the goods were in the bin they had left. Nothing reconciled the two, and
nothing ever would have: the app read bin content in two places and wrote it in none.

On a location that keeps bins, the two pictures diverge from the first move an operator makes, and
every downstream answer — availability, a pick BC raises itself, a bin content report, a physical
inventory — is taken from the picture that was never updated.

The decision recorded here is that **Business Central owns bin-level stock**. Where it keeps bins,
what it believes is what is true, and the app's job is to keep it that way.

## What it does

A finished job is turned into a `Warehouse Journal Line` with `Entry Type = Movement`, a from-bin and
a to-bin, and handed to `Whse. Jnl.-Register Line` — codeunit 7301, the same one the base application
registers its own put-aways, picks and movements with. That produces two warehouse entries, maintains
bin content on both ends, and writes a warehouse register, exactly as a movement registered through a
warehouse activity does.

The shape of the journal line is copied from `Whse.-Activity-Register`, deliberately and field by
field, including the two branches for directed and non-directed locations that decide whether the
quantity is expressed in the line's unit of measure or in the item's base unit. A warehouse entry
this app writes is meant to be indistinguishable from one the base application wrote, because
anything that can tell them apart is a report that will one day disagree with itself.

Before registering, the line goes through `WMS Management.CheckWhseJnlLine` with the same source
option the warehouse journal page uses. That is what refuses a move the from-bin cannot supply, or a
bin whose warehouse class does not accept the item. Those refusals are Business Central's own rules
about its own bins, and the app does not second-guess them: if the check fails, the job does not
finish.

## Why it is not a feature

The same argument as posting, and it lands the same way. A warehouse does not turn *registration* on;
it turns **directed work** on and then decides what finishing a job should tell Business Central. A
second toggle would only create a state where directed work is on, registration is off, and nothing
on the page can explain why the bins disagree.

So the module carries an interface, two implementations, a buffer table and a small facade, and
appears in the permission sets like anything else. It is a library.

## The choice, and where it lives

`WHA Warehouse Task Setup` gains **Warehouse registration method**, an extensible enum with two
values. The setup page shows the chosen value's own description underneath it, so the consequence is
readable before the floor starts moving stock.

| Value | What finishing a job does |
|---|---|
| **Do not tell Business Central** | Nothing. The app moves the goods in its own records and the bins are left where they were. |
| **Register a warehouse movement** | A warehouse movement is registered. Bin content and warehouse entries follow the floor. |

**The value a fresh install and every upgrade lands on is *Do not tell Business Central*.** That is
not caution for its own sake: turning this on is a decision about who owns bin-level stock, and it is
a customer conversation rather than a default. Every company that has been running the app until now
keeps behaving exactly as it did.

## The buffer

`WHA Whse. Move Request` (table 50800, `TableType = Temporary`) is what a caller hands over. One row
is one move: an item, a quantity, a from-bin and a to-bin at one location, with the lot or serial
number if there is one. `Registered` and `Warehouse Entry No.` are filled in on the way back, so a
caller can see which of its moves reached Business Central and find the entry it produced.

## What counts as a move

This is the part worth reading twice, because what the module *refuses* to do is most of its value.

A move is registered only when **both ends are known bins at one location**. Everything else produces
nothing:

- **A pick that ends at a shipment has no destination bin.** What happens to that stock is decided by
  posting the shipment. Registering a one-sided movement here would be an adjustment the app never
  decided to make, and would double-count the moment the shipment was posted.
- **A put-away of goods that have just arrived has no source bin.** The receipt is what brings them
  into stock.
- **A handling unit standing at another location** is a transfer, not a bin move.
- **A location that keeps no bins** has no bin-level record to keep true. That move is *passed over*,
  not refused — nothing is wrong with it, there is simply nothing there to record it against.

A line that is malformed rather than inapplicable — no item, no quantity, no location, one bin, or
the same bin twice — is an error, and it names which. That distinction is the whole design: a caller
that builds nonsense hears about it immediately, and a warehouse that is simply configured
differently is not shouted at.

## Who calls it

| Feature | When | What it registers |
|---|---|---|
| `FEAT-TASK-001` directed work | Finishing a job, in full or short | A job naming a handling unit registers **every line on the unit**, because that is what the app moves. A job naming only an item registers that item, at the quantity the operator actually handled. |

The call sits **before** the app moves the handling unit, and the ordering is load-bearing: the bin
the goods came from is readable then and is not afterwards. It also means a move Business Central
refuses stops the completion, so the app never holds a pallet in a bin that Business Central rejected.

## Testing

The same split as posting, and the same honest limit.

- **What a finished job would tell Business Central** is covered end to end. The test project binds
  `WHA Test Whse. Reg. Recorder` to its own enum value, drives a real job from release to completion,
  and asserts what was handed over: which bins, which quantity, which lot, and which of the five
  not-a-move cases produced nothing.
- **What `Whse. Jnl.-Register Line` does with it** is not covered. It needs a location with bins,
  items, bin content to take from, and — per `CLAUDE.md` — the W1 container this project still does
  not have. **No warehouse entry has ever been written by this module.**

## Known gaps

- **Nothing registers on a directed put-away and pick location has been proven.** The code has the
  branch for it, taken from the base application, and the zone codes are read from the bin. Whether a
  real WMS location accepts what this builds is untested, and that is where the standard checks are
  strictest.
- **Item tracking is carried, not created.** The lot or serial on the pallet line reaches the
  warehouse entry. No reservation entry or tracking specification is built, so an item whose tracking
  code demands warehouse tracking may be refused by `CheckWhseJnlLineTracking`.
- **Expiry is not carried.** `Warehouse Journal Line` has `Expiration Date` and `New Expiration Date`
  and this module sets neither, because nothing in the app refers to expiry at all. That is the first
  of the three rows [gap-analysis.md](gap-analysis.md) says to settle first, and it reaches further
  than this module.
- **A move crossing locations is not handled.** It is a transfer order, and nothing here raises one.
- **The handling unit is still moved by the app, not by the registration.** Two records now say where
  the goods are, and they are kept in step by ordering rather than by one deriving from the other.
  Making bin content the single source is a larger change than this segment, and it would reach the
  handling unit's own model.
- **Nothing reverses.** A job cannot be un-completed, so a movement registered in error is corrected
  in Business Central's own warehouse journal, not here.
