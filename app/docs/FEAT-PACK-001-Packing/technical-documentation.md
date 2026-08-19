# FEAT-PACK-001 - Packing

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> The catalogue entry names four things — packing station UI, cartonisation, pack verification and
> packing list output. Segment 1 does **two** of them: the station and the verification. Cartonisation
> (choosing which box to use) and the packing list are not started, for the reasons at the end.

## Business process

Goods are picked loose and have to leave in something. Packing is where that happens:

1. A packer stands at a **bench** and opens a **carton**.
2. They put goods into it, one kind at a time.
3. Somebody **checks** what went in against what should have.
4. The carton is **closed**, and is then a sealed handling unit like any other — it can be labelled,
   moved by a warehouse task, nested onto a pallet, and shipped.

A carton somebody walked away from is **abandoned**, not deleted: whatever was already put in it
stays in it, so the box on the bench and the system still agree.

### Delivered so far

**Segment 1** — the bench, the packing session, verification, and closing the carton.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Pack Setup` | 50400 | Single-record feature setup |
| `WHA Pack Station` | 50401 | One packing bench |
| `WHA Pack Session` | 50402 | One carton being packed, and who did it |

**A carton is a handling unit — this feature adds no container of its own.** `WHA Pack Session`
points at a `WHA Handling Unit` and the goods go on that unit's content lines. So the moment a
carton is closed, everything already built knows what it is: labelling can give it an SSCC, directed
work can move it, handling units can nest it onto a pallet, and the integration surface reports it
when it ships. A packing-specific "box" table would have been a second kind of container that none
of that machinery understood.

### `WHA Pack Session`

| Field | Type | Notes |
|---|---|---|
| `Entry No.` | `Integer` | Primary key, `AutoIncrement` — no number series; a session is a record of work, not a document people quote |
| `Station Code` | `Code[20]` | The bench |
| `Handling Unit No.` | `Code[20]` | The carton. Not editable — it is created with the session |
| `Status` | `Enum "WHA Pack Session Status"` | Packing / Verified / Closed / Cancelled. Not editable |
| `Packed By User ID` / `Verified By User ID` | `Code[50]` | **Recorded separately, on purpose** — see below |
| `Started At` / `Closed At` | `DateTime` | Stamped by the life cycle |
| `Line Count` / `Total Quantity` | `Integer` / `Decimal` | FlowFields over the carton's content lines |

Keys: `PK` on `Entry No.` (clustered), plus `Carton` (`Handling Unit No.`) and `Work`
(`Status`, `Station Code`).

**Who packed and who checked are two fields, not one.** In a warehouse that takes verification
seriously they are two different people, and a single "user" field would quietly make that
unprovable. Nothing in segment 1 *enforces* that they differ — that is a policy decision nobody has
made yet — but the data supports asking the question.

### `WHA Pack Setup`

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Require Verification` | On by default. A station that checks nothing is not doing the job people think it is |
| `Close Unit When Closed` | On by default — the carton has been taped shut, so the handling unit stops accepting contents too |
| `Default Station Code` | The bench offered first when somebody opens the packing screen |

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Pack Setup` | table | 50400 | `app/src/Packing/tables/PackSetup.Table.al` |
| `WHA Pack Station` | table | 50401 | `app/src/Packing/tables/PackStation.Table.al` |
| `WHA Pack Session` | table | 50402 | `app/src/Packing/tables/PackSession.Table.al` |
| `WHA Pack Session Status` | enum | 50400 | `app/src/Packing/enums/PackSessionStatus.Enum.al` |
| `WHA IPackSession` | interface | — | `app/src/Packing/interfaces/IPackSession.Interface.al` |
| `WHA Pack Session Logic` | codeunit | 50400 | `app/src/Packing/codeunits/PackSessionLogic.Codeunit.al` |
| `WHA Pack Feature Setup` | codeunit | 50401 | `app/src/Packing/codeunits/PackFeatureSetup.Codeunit.al` |
| `WHA Pack App Area Sub.` | codeunit | 50402 | `app/src/Packing/codeunits/PackAppAreaSub.Codeunit.al` |
| `WHA Demo Pack` | codeunit | 50403 | `app/src/Packing/codeunits/DemoPack.Codeunit.al` |
| `WHA Pack Appl. Area Setup` | tableextension | 50400 | `app/src/Packing/tableextensions/PackApplAreaSetup.TableExt.al` |
| `WHA Pack Setup` | page | 50400 | `app/src/Packing/pages/PackSetup.Page.al` |
| `WHA Pack Stations` | page | 50401 | `app/src/Packing/pages/PackStations.Page.al` |
| `WHA Pack Station Card` | page | 50402 | `app/src/Packing/pages/PackStationCard.Page.al` |
| `WHA Packing Station` | page | 50403 | `app/src/Packing/pages/PackingStation.Page.al` |
| `WHA Pack Sessions` | page | 50404 | `app/src/Packing/pages/PackSessions.Page.al` |
| `WHA API Pack Station` | page | 50405 | `app/src/Packing/pages/APIPackStation.Page.al` |
| `WHA API Pack Session` | page | 50406 | `app/src/Packing/pages/APIPackSession.Page.al` |
| `WHA API Demo Pack` | page | 50407 | `app/src/Packing/pages/APIDemoPack.Page.al` |
| `WHA Packing Tests` | codeunit | 51006 | `test/src/codeunits/PackingTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.Packing`, from the reserved block `50400..50449`.
Core changed only by gaining a `WHA Feature` enum value.

## Logic

Table triggers delegate to `WHA IPackSession`, implemented by `WHA Pack Session Logic`:

| Operation | Behaviour |
|---|---|
| `Trigger_OnInsert` | Stamps who started packing and when |
| `Trigger_OnDelete` | Refuses a session that is verified or closed — it produced a carton that may already have left |
| `Start` | Checks the bench exists and is in use, creates the carton at the bench's location and bin, opens the session |
| `PackItem` | Adds a content line to the carton. Refuses a session that is no longer packing, and refuses a line with no item or no quantity |
| `Verify` | Records who checked. Refuses an empty carton — there is nothing to look at |
| `Close` | Refuses an empty carton, and an unverified one when the setup asks for a check. Then closes the handling unit if the setup says so |
| `Cancel` | Abandons the session and **leaves the carton and its contents alone** |

**Nothing is deleted when packing is abandoned.** A half-packed box exists physically; making its
contents vanish from the system would leave somebody holding a box the system says is empty.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHAPacking` bound to
`WHA Pack Feature Setup` (guided setup step 70); `Application Area Setup` gained `WHA Packing`; the
app-area subscriber sets it from `Enabled`; the setup page is `ApplicationArea = All` while the bench
and session pages carry `WHAPacking`. The API pages guard their write triggers with `CheckEnabled`.

**No number series of its own.** The carton is numbered as the handling unit it is, from the
handling unit series, which now lives on the handling unit setup; the session is numbered by the platform. Adding a series of its own for a
record nobody quotes would have been ceremony.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Packing` | `packing` | `WHA API Pack Station` | read, create, modify — not delete |
| | | `WHA API Pack Session` | **read only** |
| `Warehouse Advanced - Demo Packing` | `demoPacking` | `WHA API Demo Pack` | run `importDemoData` only |

Sessions are read-only to agents and there are **no bound actions for packing, checking or closing**
— the same rule as the handheld. Packing is a claim about what physically went into a box, made by
somebody who was holding it. An agent can tell you what was packed; it cannot pack.

## Demo data

`WHA Demo Pack` seeds three benches (`DEMO-PACK-01..03`, one of them blocked), sets the first as the
default, and packs **one worked example**: a carton opened, filled, checked and closed, so the
session list is not empty on a fresh company. Idempotent — the example is created only when no
session exists for the first bench. `Import()` also builds the `WHA-PACK` RapidStart package.

## Tests

`WHA Packing Tests` (codeunit 51006), 16 tests: starting opens a carton at the bench's location;
blocked and unknown benches are refused; goods go into the carton and the totals follow; packing
nothing is refused; an empty carton can be neither checked nor closed; verification is required or
not according to setup; checking records who checked; closing closes the handling unit, or leaves it
open when the setup says so; nothing can be added to a closed carton; abandoning leaves the contents
in place; a closed session cannot be deleted; and demo idempotency.

## Not done

- **Cartonisation.** Nothing suggests which box to use, and there is no carton-size master data. Doing
  it properly needs item dimensions and weights that nobody has confirmed this customer maintains —
  and doing it badly produces suggestions packers learn to ignore.
- **Packing list output.** No document, no report, no layout. It belongs with the label templates in
  `FEAT-LBL-001`, and both need to know what the customer actually prints.
- **No link to an order or a shipment.** A carton is packed at a bench, not *for* anything. Until
  directed work is tied to source documents, there is nothing to pack against — the same gap
  `FEAT-TASK-001` records.
- **Verification is a claim, not a comparison.** `Verify` records that somebody said they checked. It
  does not re-scan the contents or compare them against an expected list, because there is no
  expected list to compare against yet. That is the honest limit of it, and the getting-started text
  says so to the person doing it.
- **Nothing enforces that the packer and the checker differ.** The data records both; no rule
  compares them.
- **No weight or dimensions** on the carton.
- **Getting-started in the customer language** — the language has not been confirmed.
