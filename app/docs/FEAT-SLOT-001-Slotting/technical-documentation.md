# FEAT-SLOT-001 - Slotting

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Standard Business Central has bin ranking and warehouse classes, and put-away already uses them.
> What it does not have is anything that works out *which* items deserve the good bins. That is the
> gap claimed here — and it is worth noting that this feature's answers are only as good as the
> app's own pick history, which on a fresh installation is empty.

## Business process

Bin ranking says which bins are good. Nothing says which items deserve them, so in practice items
keep whatever bin they were first put in.

1. An **analysis** measures how much every item moved at a location over a period, from the picks the
   warehouse has already done, and gives each one a **class** — A, B or C — by the usual Pareto split.
2. A **proposal** is raised for every classified item that is picked from a bin worse than its class
   deserves.
3. Somebody answers the proposal: **reject** it, or say where the goods should go and **accept** it,
   which raises the movement work.

### Delivered so far

**Segment 1** — velocity analysis, two bases, the ABC split, proposals against bin ranking, and the
movement raised on acceptance.

## Where the numbers come from

**Completed pick tasks, and nothing else.** No ledger, no posted entries, no inventory movement
history — the app measures the work it directed itself.

That is a real limitation and it cuts both ways. It means the analysis reflects what the *warehouse*
did rather than what was *sold*, which is the right measure for slotting. It also means a company that
has just installed the app has no history, and the honest answer to "why are there no proposals" is
that nothing has been picked yet.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Slotting Setup` | 50300 | Single-record feature setup |
| `WHA Item Velocity` | 50301 | How much one item moved at one location |
| `WHA Slotting Proposal` | 50302 | One suggested move, and what was decided |

### `WHA Item Velocity`

Keyed by location, item and variant. `Movements` counts picks — one pick is one trip — and
`Quantity Moved` sums what was taken. `Rank Value` is **kept rather than recomputed**: it is whichever
of the two the setup chose, stored so the ranking can be checked instead of trusted.

`Main Bin Code` is the bin the item is picked from most often over the period, with that bin's
ranking beside it. That pair is what a proposal is about.

### `WHA Slotting Proposal`

| Field | Notes |
|---|---|
| `Entry No.` | `AutoIncrement` |
| `Class`, `From Bin Code`, `From Bin Ranking`, `Required Bin Ranking` | The finding, stated so it can be argued with |
| `To Bin Code` | **The one editable field.** The app does not choose it |
| `Reason` | The finding in a sentence |
| `Status`, `Handled By User ID`, `Handled At` | Who answered it and when |
| `Task No.` | The movement raised on acceptance |

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Slotting Setup` | table | 50300 | `app/src/Slotting/tables/SlottingSetup.Table.al` |
| `WHA Item Velocity` | table | 50301 | `app/src/Slotting/tables/ItemVelocity.Table.al` |
| `WHA Slotting Proposal` | table | 50302 | `app/src/Slotting/tables/SlottingProposal.Table.al` |
| `WHA Velocity Class` | enum | 50300 | `app/src/Slotting/enums/VelocityClass.Enum.al` |
| `WHA Velocity Basis` | enum | 50301 | `app/src/Slotting/enums/VelocityBasis.Enum.al` |
| `WHA Proposal Status` | enum | 50302 | `app/src/Slotting/enums/ProposalStatus.Enum.al` |
| `WHA IVelocityBasis` | interface | — | `app/src/Slotting/interfaces/IVelocityBasis.Interface.al` |
| `WHA ISlottingProposal` | interface | — | `app/src/Slotting/interfaces/ISlottingProposal.Interface.al` |
| `WHA Slotting Mgt.` | codeunit | 50300 | `app/src/Slotting/codeunits/SlottingMgt.Codeunit.al` |
| `WHA Slotting Prop. Logic` | codeunit | 50301 | `app/src/Slotting/codeunits/SlottingPropLogic.Codeunit.al` |
| `WHA Slot. Feature Setup` | codeunit | 50302 | `app/src/Slotting/codeunits/SlotFeatureSetup.Codeunit.al` |
| `WHA Slot. App Area Sub.` | codeunit | 50303 | `app/src/Slotting/codeunits/SlotAppAreaSub.Codeunit.al` |
| `WHA Demo Slotting` | codeunit | 50304 | `app/src/Slotting/codeunits/DemoSlotting.Codeunit.al` |
| `WHA Velocity By Movements` | codeunit | 50305 | `app/src/Slotting/codeunits/VelocityByMovements.Codeunit.al` |
| `WHA Velocity By Quantity` | codeunit | 50306 | `app/src/Slotting/codeunits/VelocityByQuantity.Codeunit.al` |
| `WHA Slot. Appl. Area Setup` | tableextension | 50300 | `app/src/Slotting/tableextensions/SlotApplAreaSetup.TableExt.al` |
| `WHA Slotting Setup` | page | 50300 | `app/src/Slotting/pages/SlottingSetup.Page.al` |
| `WHA Item Velocities` | page | 50301 | `app/src/Slotting/pages/ItemVelocities.Page.al` |
| `WHA Slotting Proposals` | page | 50302 | `app/src/Slotting/pages/SlottingProposals.Page.al` |
| `WHA API Item Velocity` | page | 50303 | `app/src/Slotting/pages/APIItemVelocity.Page.al` |
| `WHA API Slotting Proposal` | page | 50304 | `app/src/Slotting/pages/APISlottingProposal.Page.al` |
| `WHA API Demo Slotting` | page | 50305 | `app/src/Slotting/pages/APIDemoSlotting.Page.al` |
| `WHA Slotting Tests` | codeunit | 51011 | `test/src/codeunits/SlottingTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.Slotting`, from the reserved block `50300..50349`. Core gained a
`WHA Feature` enum value; nothing else outside the feature changed.

## Bases — what counts as work

`WHA IVelocityBasis` turns a count of trips and a quantity moved into the one figure the ranking
sorts on. **It never decides the class**, so the Pareto split is identical whichever basis a
warehouse picks — only the order changes.

| Basis | Ranks on | Right when |
|---|---|---|
| **How often it is picked** (default) | Number of picks | The cost of a pick is the walk, and the walk happens once per trip whatever comes back |
| **How much of it is picked** | Quantity picked | The handling rather than the walking is the work |

The two give genuinely different answers — an item fetched fifty times in ones against an item
fetched twice by the pallet — and which is right is a statement about how that warehouse works. The
setup page shows the chosen basis's own description next to the field for exactly that reason.

## The classification

Rows are ordered by `Rank Value` descending, and a running share of the location's total is
accumulated. An item lands in **A** while the running share is within `Class A Percent`, in **B**
while within A plus `Class B Percent`, and in **C** after that. Ships as 20/30.

An item with fewer picks than `Fewest picks worth classifying` (ships at 2) is left
**Unclassified**. An item picked once is not slow moving; it is unmeasured, and calling it class C
would send somebody to move stock on the strength of a single trip.

**Re-running replaces the previous answer for that location.** A velocity is a statement about a
period, and two periods added together is a statement about neither.

## Proposals stop short of choosing

A proposal says a class-A item is picked from a bin ranked 10 when its class needs 80. It does **not**
say where to move it, because nothing in this app knows which good bin is free — there is no
occupancy model, no capacity, and no reservation.

So `To Bin Code` is blank and editable, and accepting has two shapes:

- **with a destination** — the decision is recorded *and* a movement task is raised, from the bin the
  item is picked from now to the bin somebody chose;
- **without one** — the decision alone is recorded, and **Raise the move** can raise the work later
  once somebody knows where the space is.

An open proposal for an item stops a second one being made for it, so re-running the analysis weekly
does not build a pile of identical suggestions for the item nobody has got round to moving. An
answered proposal cannot be answered again or deleted: what was suggested and what was decided is the
only record of why the stock sits where it sits.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHASlotting` bound to
`WHA Slot. Feature Setup` (guided setup step 130); `Application Area Setup` gained `WHA Slotting`
through this feature's own tableextension; the setup page is `ApplicationArea = All` while the
slotting pages carry `WHASlotting`. Directed work has to be enabled as well — both for the history the
analysis reads and for the movements an accepted proposal raises.

**No new number series.**

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Slotting` | `slotting` | `WHA API Item Velocity` | **read only** |
| `Warehouse Advanced - Slotting` | `slotting` | `WHA API Slotting Proposal` | read and modify — which in practice means **filling in where the goods should go** |
| `Warehouse Advanced - Demo Slotting` | `demoSlotting` | `WHA API Demo Slotting` | run `importDemoData` only |

An agent cannot accept or reject: those are bound actions and no action is exposed. It can read the
findings, and it can suggest a destination by writing `toBinCode` — a suggestion a person still has to
accept.

## Demo data

`WHA Demo Slotting` seeds **no records of its own**. It runs the analysis and the proposals against
whatever picking the company has already done, at the first location it finds. A velocity is a
statement about work that was actually done, and inventing one would produce a class nobody could
check against anything.

On a company that has run the directed work sample data there is something to measure; on an empty one
the import correctly produces nothing. `Import()` builds the `WHA-SLOT` RapidStart package either way.

## Tests

`WHA Slotting Tests` (codeunit 51011), 13 tests: velocity is measured from the picks already done,
including where the item is picked from; the fastest items are class A; an item picked too few times is
left unclassified; the quantity basis ranks differently from the movement basis; re-running replaces
rather than doubles; an analysis without a location is refused; a fast item in a poor bin is proposed
and a fast item in a good bin is not; the same item is not proposed twice while one is open; accepting
with a destination raises the movement and accepting without one records the decision only; an answered
proposal cannot be answered again or deleted; and demo idempotency.

## Not done

- **It does not choose destinations.** See above. This is the largest gap, and closing it needs a bin
  capacity and occupancy model the app does not have.
- **Only pick history counts.** Put-aways, movements and counts are ignored, so an item that is
  replenished constantly but picked rarely looks slow.
- **No re-slotting worksheet.** The catalogue names one. What ships is a list of proposals with two
  answers; there is no worksheet that plans a whole aisle's re-slot as one operation with the moves
  sequenced.
- **No seasonality.** One period, one class. An item that sells only in December is class C in June and
  nothing says so.
- **Nothing schedules the analysis.** A job queue entry has to be created by an administrator.
- **Getting-started in the customer language** — the language has not been confirmed.
