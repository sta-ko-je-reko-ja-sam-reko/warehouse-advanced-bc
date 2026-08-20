# Location configuration

Which Business Central location settings this app works with, which it refuses, and why. Business
Central has warehouse machinery of its own, and some combinations of its flags put two queues over the
same stock with neither able to see the other.

This is configuration, not code: nothing here is a setting in Warehouse Advanced. It is a statement
about how a Business Central location has to be set up for the app to be correct on it.

## The short version

| Location flag | What this app needs |
|---|---|
| `Require Receive` | **On.** The app's only document sources are warehouse receipts |
| `Require Shipment` | **On.** Likewise, warehouse shipments |
| `Require Put-away` | **Off.** Business Central raises its own put-aways otherwise |
| `Require Pick` | **Off.** Business Central raises its own picks otherwise, and the write-back cannot work |
| `Bin Mandatory` | **Your choice.** It decides whether warehouse registration has anything to record |
| `Directed Put-away and Pick` | **Not for directed work.** See below — Business Central forces the two flags above on with it |

## Why put-away and pick have to be off

**`Require Put-away`:** posting a warehouse receipt at such a location creates a warehouse put-away
document — `Whse.-Post Receipt` calls `Create Put-away` when the flag is set. The app has already
raised its own put-away task from the same receipt line. Two documents, the same goods, and nothing
that reconciles them: an operator is sent to the same bin twice, and the second one finds nothing.

**`Require Pick`:** the same duplication, plus a second problem that is easier to demonstrate.
`Warehouse Shipment Line` refuses a `Qty. to Ship` greater than `Qty. Picked - Qty. Shipped` on a
pick-required location. This app never registers a Business Central pick, so `Qty. Picked` stays zero
and **every write-back fails**. The *Write back to the document* setting and `Require Pick` cannot both
be on.

**The app now refuses rather than letting this happen.** Raising work from a warehouse receipt or
shipment at a location that requires Business Central's own put-away or pick is an error that names
the location. Work created **by hand** is not blocked — it is not tied to a document, so nobody asked
for it twice — but the same physical duplication is possible if a document covers the same goods, and
nothing detects that.

## Directed put-away and pick

Turning `Directed Put-away and Pick` on in Business Central **forces `Require Receive`,
`Require Shipment`, `Require Put-away` and `Require Pick` all on**, and will not let them be turned
back off. That is base application behaviour, in the `Location` table's own validation, and there is
no configuration that avoids it.

So a directed location cannot use this app's directed work. What it *can* use:

| Feature | At a directed location |
|---|---|
| `FEAT-TASK-001` directed work, and the handheld on top of it | **No.** Business Central runs its own put-away and pick queue there |
| Warehouse registration of moves | Not reached, because there are no tasks to register |
| `FEAT-CNT-001` counting and `FEAT-QC-001` quality hold, including posting | **Yes.** Posting is written as the two halves such a location requires — see [inventory-posting.md](inventory-posting.md) |
| Everything with no bin-level behaviour — dock and yard, labelling, labour, analytics | Yes |

That is a real limit on the app, not a preference, and it follows from Business Central owning
bin-level stock — the decision recorded in
[warehouse-registration.md](warehouse-registration.md). An app that wanted to run directed work at a
directed location would have to *be* Business Central's put-away and pick — creating and registering
`Warehouse Activity Line` records rather than a queue of its own. Nothing in this app does that, and
whether it should is a scope question the capability register has never been asked.

## Which of Business Central's own warehouse documents this app can read

The rule above decides this, and it decides most of it against us. Business Central's internal
warehouse documents test the location before they will exist at all:

| Document | Location it needs | Reachable here |
|---|---|---|
| Warehouse receipt | `Require Receive` | **Yes** — a task source since segment 3 |
| Warehouse shipment | `Require Shipment` | **Yes** — a task source since segment 3 |
| **Movement worksheet** | `Bin Mandatory` only | **Yes** — a task source, and the shape fits exactly |
| Whse. internal put-away | `Require Put-away` **and** `Directed Put-away and Pick` | **No** |
| Whse. internal pick | `Require Pick` **and** `Directed Put-away and Pick` | **No** |
| Warehouse pick for production or assembly | `Require Pick` | **No** |

The four marked *No* are not unbuilt. They are **unreachable**: every location they can exist at is a
location this app refuses to raise work in, because Business Central is already raising its own there.
Adding them as task sources would add code that can never run.

Transfer orders are not on the list because they do not need to be — a transfer at a warehouse location
flows through a warehouse receipt and a warehouse shipment, both of which are already sources.

**So the honest summary is that the list of document sources is finished**, not partly built, unless the
app changes shape. Which brings the same fork as the section above: an app that wanted the other four
would have to *be* Business Central's put-away and pick, creating and registering `Warehouse Activity
Line` records instead of keeping a queue of its own. That is a different product, and it is the one
scope decision this project has never actually taken.

## Bin mandatory, and what registration does

| Location | Finishing a job | Posting a count difference or a write-off |
|---|---|---|
| No bins | Nothing to register; the app moves the goods in its own records | A bin-less item journal line |
| Bins, not directed | A warehouse movement, if the setting asks for it | An item journal line carrying the bin |
| Directed | *(directed work is not used here)* | Two halves: a warehouse adjustment, then a bin-less item journal line |

## What is not checked

- ~~**Warehouse employees.**~~ **Now checkable**, behind *Who may be given work* on the warehouse task
  setup, which ships off. With it on, a job can only be assigned to somebody on Business Central's
  `Warehouse Employee` list for that location. Left off, the list is not consulted and an operator can
  hold work at a location Business Central would not let them into. Turning it on does not revisit work
  already assigned.
- **Anything at all about a location created after the fact.** The guard runs when work is raised from
  a document. Turning `Require Pick` on afterwards leaves the tasks already raised standing, and
  nothing revisits them.
- **Locations reached by hand.** A task typed in by somebody names its own location and bins, and only
  the document sources are guarded.
- **Cross-location movement.** A handling unit that changes location is a transfer, and nothing in this
  app raises a transfer order. Registration passes such a move over rather than inventing one.
