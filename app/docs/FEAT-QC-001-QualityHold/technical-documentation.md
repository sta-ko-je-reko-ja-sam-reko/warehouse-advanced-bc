# FEAT-QC-001 - Quality Hold

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Standard Business Central can block an item and block a bin. What it cannot do is stop *these
> particular goods* — one pallet, and everything on it — which is what a warehouse means by
> quarantine. That is the gap this feature claims, and it is the one Phase 0 should test hardest,
> because a customer who quarantines by moving stock to a blocked bin may need none of it.

## Business process

Somebody finds a problem with goods that are already in the warehouse. Until it is settled, nobody
should touch them — and "nobody should touch them" has to be enforced by the system, not by a label
on the pallet.

1. A **hold** is placed on a handling unit, with a **reason** and a note of what was found. The unit
   stops being available, and so does everything nested inside it.
2. Somebody inspects the goods and **decides** what happens to them — release, rework or scrap.
3. The hold is **released**. The decision is carried out on the unit and on everything held with it,
   and who lifted it and when is recorded.

The hold record stays for ever, whether or not the hold is still on. That is the audit trail.

### Delivered so far

**Segment 1** — the hold, the cascade to nested units, three dispositions, and the enforcement that
makes a hold mean something.

## What makes a hold real

A quarantine that only writes a record is a label on a pallet. This one changes the handling unit's
own **status**, which is what the rest of the app already reads:

| Where | What happens |
|---|---|
| `WHA Handling Unit Line` | Contents cannot be added or changed — the unit is not open |
| `WHA Warehouse Task` | No work can be planned for the unit, so nobody is sent to fetch it |
| `WHA Pack Session` | The unit cannot be opened as a carton to pack into |
| `WHA Repl. Handling Units` | Held stock does not count as pick-face stock |

**None of those modules know that quality hold exists.** The status enum gained two values through
this feature's own `enumextension` — `WHAOnHold` and `WHAScrapped` — and the modules that gate on
status were changed to state their rule **positively**: work can be planned for a unit that is *open
or closed*, and replenishment measures units that are *open or closed*. Neither names a hold, neither
gained a `using` for this namespace, and a third state added later is refused by both for free.

The alternative — every module asking quality hold whether a unit is held — would have made a feature
the customer may not even want a dependency of the task queue.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Quality Hold Setup` | 50550 | Single-record feature setup |
| `WHA Quality Hold` | 50551 | One hold on one handling unit |

### `WHA Quality Hold`

| Field | Type | Notes |
|---|---|---|
| `Entry No.` | `Integer` | Primary key, `AutoIncrement`. A hold is an event, so it is numbered by the platform rather than by a number series — the same choice `WHA Pack Session` made |
| `Handling Unit No.` | `Code[20]` | What was stopped |
| `Location Code`, `Bin Code` | | **A snapshot** taken when the hold was placed. It does not follow the unit afterwards, because it records where the problem was found |
| `Reason` | `Enum "WHA Hold Reason"` | Why it was stopped |
| `Description` | `Text[100]` | What was found, in the words of whoever found it |
| `Status` | `Enum "WHA Hold Status"` | On hold / Released |
| `Disposition` | `Enum "WHA Hold Disposition"` | What happens to the goods. Editable while the hold is on, refused afterwards |
| `Cascaded From Entry No.` | `Integer` | The hold that brought this one with it. Blank means the unit was stopped in its own right |
| `Held By User ID` / `Held At` | | Who stopped the goods, and when |
| `Released By User ID` / `Released At` | | Who let them go, and when. **Deliberately separate fields** — in a warehouse that takes quality seriously they are two people |
| `Previous Unit Status` | `Enum "WHA Handling Unit Status"` | What the unit was before the hold, so releasing puts it back to that rather than to a fixed state |

### `WHA Quality Hold Setup`

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Default Reason` | What a hold placed from the handling unit card is given |
| `Hold what is inside as well` | Ships **on**. Off holds only the named unit |
| `Decide before releasing` | Ships **on**. Off lets a hold be lifted with no decision, and records it as *released back into stock* |

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Quality Hold Setup` | table | 50550 | `app/src/QualityHold/tables/QualityHoldSetup.Table.al` |
| `WHA Quality Hold` | table | 50551 | `app/src/QualityHold/tables/QualityHold.Table.al` |
| `WHA Hold Reason` | enum | 50550 | `app/src/QualityHold/enums/HoldReason.Enum.al` |
| `WHA Hold Status` | enum | 50551 | `app/src/QualityHold/enums/HoldStatus.Enum.al` |
| `WHA Hold Disposition` | enum | 50552 | `app/src/QualityHold/enums/HoldDisposition.Enum.al` |
| `WHA HU Status Hold` | enumextension | 50550 | `app/src/QualityHold/enumextensions/HUStatusHold.EnumExt.al` |
| `WHA IQualityHold` | interface | — | `app/src/QualityHold/interfaces/IQualityHold.Interface.al` |
| `WHA IHoldDisposition` | interface | — | `app/src/QualityHold/interfaces/IHoldDisposition.Interface.al` |
| `WHA Quality Hold Logic` | codeunit | 50550 | `app/src/QualityHold/codeunits/QualityHoldLogic.Codeunit.al` |
| `WHA Quality Hold Mgt.` | codeunit | 50551 | `app/src/QualityHold/codeunits/QualityHoldMgt.Codeunit.al` |
| `WHA QC Feature Setup` | codeunit | 50552 | `app/src/QualityHold/codeunits/QCFeatureSetup.Codeunit.al` |
| `WHA QC App Area Sub.` | codeunit | 50553 | `app/src/QualityHold/codeunits/QCAppAreaSub.Codeunit.al` |
| `WHA Demo Quality Hold` | codeunit | 50554 | `app/src/QualityHold/codeunits/DemoQualityHold.Codeunit.al` |
| `WHA Disp. Pending` | codeunit | 50555 | `app/src/QualityHold/codeunits/DispPending.Codeunit.al` |
| `WHA Disp. Release` | codeunit | 50556 | `app/src/QualityHold/codeunits/DispRelease.Codeunit.al` |
| `WHA Disp. Rework` | codeunit | 50557 | `app/src/QualityHold/codeunits/DispRework.Codeunit.al` |
| `WHA Disp. Scrap` | codeunit | 50558 | `app/src/QualityHold/codeunits/DispScrap.Codeunit.al` |
| `WHA QC Appl. Area Setup` | tableextension | 50550 | `app/src/QualityHold/tableextensions/QCApplAreaSetup.TableExt.al` |
| `WHA Quality Hold Setup` | page | 50550 | `app/src/QualityHold/pages/QualityHoldSetup.Page.al` |
| `WHA Quality Holds` | page | 50551 | `app/src/QualityHold/pages/QualityHolds.Page.al` |
| `WHA Quality Hold Card` | page | 50552 | `app/src/QualityHold/pages/QualityHoldCard.Page.al` |
| `WHA API Quality Hold` | page | 50553 | `app/src/QualityHold/pages/APIQualityHold.Page.al` |
| `WHA API Demo Quality Hold` | page | 50554 | `app/src/QualityHold/pages/APIDemoQualityHold.Page.al` |
| `WHA Quality Hold Tests` | codeunit | 51009 | `test/src/codeunits/QualityHoldTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.QualityHold`, from the reserved block `50550..50599`.

**Changes outside the feature**, all of them one-directional:

| Object | Change |
|---|---|
| `WHA Feature` (Core) | A `WHAQualityHold` value |
| `WHA Warehouse Task Logic` (Directed work) | Refuses work for a unit that is not open or closed. Does not name a hold |
| `WHA Repl. Handling Units` (Replenishment) | Measures only units that are open or closed. Does not name a hold |
| `WHA Handling Unit Card` (Handling units) | **Put on hold** and **Quality holds** actions, carrying this feature's application area and `AccessByPermission`, exactly as labelling's action does |

## Dispositions — one thing each

`WHA IHoldDisposition` owns exactly one thing: **the state the handling unit is left in**. It never
touches the hold record, so a disposition somebody adds later cannot get the audit trail wrong — the
stamping of who released it and when happens in one place regardless of the decision.

| Value | What it does to the unit |
|---|---|
| **Not decided yet** (default) | Refuses the release. A hold lifted without a decision puts the goods back into stock by default, which is the outcome quality hold exists to prevent |
| **Release back into stock** | Back to `Previous Unit Status` — a pallet that was closed and ready to ship is closed and ready to ship again, not quietly reopened |
| **Rework** | **Open**, whatever it was. Goods that are going to be put right have to be got at |
| **Scrap** | **Scrapped**, which keeps it out of every queue, worksheet and measurement in the app |

`WHA Hold Disposition` is extensible, so *return to vendor*, *downgrade* or *sell as seconds* is an
`enumextension` value and one codeunit.

`Describe()` puts one line on the hold card saying what the decision will do, before somebody makes
it.

## The cascade

Holding a pallet holds everything nested inside it, to any depth, and **each unit gets its own hold
record** pointing back at the one that brought it with it. That is more records than a single flag
would need, and it is the point: "why is this carton quarantined" has an answer per carton, and the
answer survives the pallet being released.

Releasing the outer hold releases everything held with it, applying the same decision. Releasing a
cascaded hold **on its own is refused** and says which hold to release instead — letting the carton
out while the pallet it stands on is still held is how quarantined goods walk out of a warehouse.

A unit that was already on hold in its own right is not swept into somebody else's cascade, and is
not released by it either.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHAQualityHold` bound to
`WHA QC Feature Setup` (guided setup step 110); `Application Area Setup` gained `WHA Quality Hold`
through this feature's own tableextension; the setup page is `ApplicationArea = All` while the hold
pages carry `WHAQualityHold`.

**No number series of its own**, because a hold is an event and the platform numbers it.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Quality Hold` | `qualityHold` | `WHA API Quality Hold` | **read only** |
| `Warehouse Advanced - Demo Quality Hold` | `demoQualityHold` | `WHA API Demo Quality Hold` | run `importDemoData` only |

**The API page exposes no actions at all** — no place, no decide, no release, and no writes. This is
the strictest surface in the app, and deliberately so: placing a hold stops real goods, and lifting
one puts goods somebody was worried about back into stock. Both are decisions with a name attached,
and `Held By` / `Released By` are only worth recording if they are true.

What an agent is good for here is the question nobody has time to ask: what is still on hold, what
has been sitting there longest, what is waiting for a decision, and which reasons keep coming back.
All of that is a read.

## Demo data

`WHA Demo Quality Hold` places two holds against the handling unit sample data: `DEMO-HU-001` is held
as damaged and left waiting for a decision, which drags `DEMO-HU-002` — the carton nested on it —
into quarantine as a cascaded hold; `DEMO-HU-003`, a **closed** cage, is held for inspection, decided
and released, so the sample shows a unit going back to *closed* rather than to *open*.

It seeds nothing if those units do not exist, and skips any unit that already has a hold on record,
so re-running creates nothing new. `Import()` also builds the `WHA-QC` RapidStart package.

Scrap and rework are **not** seeded. A sample import that scraps a pallet in somebody's demonstration
company is worse than a gap in the coverage.

## Tests

`WHA Quality Hold Tests` (codeunit 51009), 17 tests: holding a unit takes it out of use and stamps who
and when; no work can be planned for a held unit; held stock stops counting as available pick-face
stock; holding a pallet holds the carton inside it and links the two, unless the setup says otherwise;
a unit already on hold cannot be held again; a shipped unit cannot be held; a hold cannot be lifted
without a decision, unless the setup allows it — and then what was actually done is recorded; releasing
to stock puts the unit back as it was; scrapping keeps the goods out of use and refuses new work;
rework opens the unit; releasing the outer unit releases what was held with it; a cascaded hold cannot
be lifted on its own; a hold cannot be deleted; the decision cannot be changed after release; and demo
idempotency.

## Not done

- **Nothing is posted.** Scrapping marks the unit and writes off nothing: no item journal, no negative
  adjustment, no ledger entry. The stock is out of use in this app and still on hand in Business
  Central. This is the same line `FEAT-CNT-001` stops at, for the same reason — posting needs the item
  journal, dimensions and a W1 container to test against.
- **No hold on an item, a lot or a bin.** Only handling units can be held. A warehouse that wants to
  quarantine *every* pallet of a lot has to hold each one, and there is nothing that finds them.
  This is the most likely first extension, and the reason `Reason` and `Disposition` are extensible
  enums rather than options.
- **No hold on the handheld.** An operator who finds damage cannot quarantine it where they are
  standing; somebody has to do it at a desk. That is exactly backwards from where the problem is
  found, and it is an operator-review question before it is a build item.
- **No return to vendor.** It needs a purchase return order, which is real posting.
- **No time limits or escalation.** Nothing notices that goods have been on hold for three weeks. The
  agent instructions point at that question because the data supports asking it even though the app
  does not ask it.
- **Getting-started in the customer language** — the language has not been confirmed.
