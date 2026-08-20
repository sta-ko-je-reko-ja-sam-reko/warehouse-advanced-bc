# FEAT-INT-001 - Integration Surface

## Source/legacy reference

N/A (greenfield).

> ## The contract in this document is a guess
>
> **No interface specification was available.** The customer does not have one, and the third-party
> WMS being replaced is not the source of a written contract we can read. The message types, the
> field names, the JSON shapes and the exchange pattern below were **designed from what a warehouse
> interface normally carries**, not from anything the customer's systems actually send today.
>
> This is a deliberate, agreed decision, not an oversight. What it means in practice:
>
> - **Assume every payload shape below is wrong in the details.** Field names will differ, extra
>   fields will be required, and at least one message type we did not think of will be needed.
> - **The feature is built so that being wrong is cheap.** The parts that are guesses are isolated
>   in one place — the handler codeunits and their JSON — and the parts that are not guesses (the
>   message spine, the life cycle, retries, duplicate suppression, the audit trail) are independent
>   of them. Replacing a payload shape is one codeunit; adding a message type is an `enumextension`
>   value plus one codeunit, and **no existing object changes**.
> - **Nothing here talks to another system over the wire.** There is no URL, no credential and no
>   transport, because none is known. The partner system posts into an API and collects from an
>   outbox. When the real transport is known it becomes its own segment, and it will not disturb
>   anything below.
>
> The things to establish before this is more than a scaffold are listed under
> "What has to come from the customer" at the end.

## Business process

The warehouse does not run alone. Something upstream tells it what has arrived and what needs to
happen; the warehouse tells that something what it did. This feature is that conversation, recorded
as messages so that both halves are auditable:

1. The partner system **posts an inbound message** — a receipt notification, or a request for work.
2. The message is **applied** to the app's own data: a handling unit appears, or a warehouse task is
   created — released to the floor, or held as a draft for review, as the setup and the message
   between them decide. The message itself is applied on arrival or left waiting, again per the
   setup.
3. A message that cannot be applied **fails with its reason recorded** and nothing half-done left
   behind. It can be corrected and tried again.
4. As work finishes, the app **fills an outbox** — a confirmation for every completed warehouse
   task, a despatch notification for every shipped handling unit.
5. The partner system **collects** those messages and **acknowledges** them, which is what stops
   them being offered again.

### Delivered so far

**Segment 1** — the message spine, the handler dispatch, and four message types: two inbound, two
outbound.

**Segment 2** — retention: the message log offered to Business Central's own retention policy
framework.

**Segment 3** — the message set widened to **twelve types**, six each way, from evidence by
analogy rather than from a customer fact. See *Segment 3 — the message set, widened by analogy*
below for where the evidence came from and what it is worth.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Integration Setup` | 50650 | Single-record feature setup |
| `WHA Integration Message` | 50651 | Every message in or out, with its body and what became of it |

### `WHA Integration Message`

| Field | Type | Notes |
|---|---|---|
| `Entry No.` | `Integer` | Primary key, `AutoIncrement` — the platform numbers messages, not a number series |
| `Direction` | `Enum "WHA Int. Direction"` | Inbound / Outbound |
| `Message Type` | `Enum "WHA Int. Message Type"` | Extensible, and it **is** the dispatch — see below |
| `Partner System` | `Code[20]` | Which system this belongs to. Defaulted from the setup |
| `External Id` | `Code[50]` | How the other side identifies the subject. **This is what makes the interface safe to retry** |
| `Correlation Id` | `Code[50]` | Ties an answer back to the request that asked for it |
| `Status` | `Enum "WHA Int. Message Status"` | New / Processed / Failed / Cancelled. Not editable |
| `Error Message` | `Text[250]` | Why it failed, in the words the app itself used |
| `Retry Count` | `Integer` | How many attempts have been made |
| `Payload` | `Blob` | The body, as JSON, exactly as sent or built |
| `Received At` / `Processed At` | `DateTime` | Stamped by the spine |
| `Record ID` | `RecordId` | What the message created, changed, or was built from |

Keys: `PK` on `Entry No.` (clustered), plus `Queue` (`Direction`, `Status`, `Message Type`),
`External` (`Message Type`, `External Id`) and `Correlation` (`Correlation Id`).

**The `External` key is the load-bearing one.** Both idempotency rules read it:

- *Inbound:* a message whose `External Id` already appears on a **processed inbound** message of the
  same type is refused. The partner system can resend anything, at any time, without creating the
  work twice.
- *Outbound:* a completed task or shipped unit is only put in the outbox if there is no **outbound**
  message of that type carrying its number. **The outbox is the state** — no "sent" flag exists on
  the warehouse task or the handling unit, so nothing has to be kept in step.

`Payload` is a `Blob` rather than a `Text` field: message bodies outgrow 2048 characters as soon as
a receipt carries a few lines, and the body must be kept **exactly** as it arrived to be worth
anything in a dispute. Read and write it through `WHA Int. Message Mgt.`, never directly.

### `WHA Integration Setup`

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Partner System` | Stamped on every message. Ships as `HOST` |
| `Process inbound messages on arrival` | Off means messages queue for review or for a scheduled run |
| `Release requested work` | On sends requested work straight to the floor; off holds it as a draft for someone here to check. A message may override it for itself |
| `Max Retry Count` | How many times a failed inbound message is tried again by the queue run. Zero means never |
| `Posting Method` | What an inbound inventory adjustment does to stock: nothing, a journal line somebody posts, or straight to the ledger. Same choice, and the same engine, as counting and quality hold |
| `Item Journal Template Name` / `Item Journal Batch Name` | Where an adjustment is written. Only read when the method writes journal lines |
| `Posting Reason Code` | Stamped on the entries an adjustment makes, so they can be told apart later |

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Integration Setup` | table | 50650 | `app/src/Integration/tables/IntegrationSetup.Table.al` |
| `WHA Integration Message` | table | 50651 | `app/src/Integration/tables/IntegrationMessage.Table.al` |
| `WHA Int. Direction` | enum | 50650 | `app/src/Integration/enums/IntDirection.Enum.al` |
| `WHA Int. Message Status` | enum | 50651 | `app/src/Integration/enums/IntMessageStatus.Enum.al` |
| `WHA Int. Message Type` | enum | 50652 | `app/src/Integration/enums/IntMessageType.Enum.al` |
| `WHA IIntegrationMessage` | interface | — | `app/src/Integration/interfaces/IIntegrationMessage.Interface.al` |
| `WHA IIntMessageHandler` | interface | — | `app/src/Integration/interfaces/IIntMessageHandler.Interface.al` |
| `WHA Integration Msg. Logic` | codeunit | 50650 | `app/src/Integration/codeunits/IntegrationMsgLogic.Codeunit.al` |
| `WHA Int. Feature Setup` | codeunit | 50651 | `app/src/Integration/codeunits/IntFeatureSetup.Codeunit.al` |
| `WHA Int. App Area Sub.` | codeunit | 50652 | `app/src/Integration/codeunits/IntAppAreaSub.Codeunit.al` |
| `WHA Int. Message Mgt.` | codeunit | 50653 | `app/src/Integration/codeunits/IntMessageMgt.Codeunit.al` |
| `WHA Int. Unhandled Message` | codeunit | 50654 | `app/src/Integration/codeunits/IntUnhandledMessage.Codeunit.al` |
| `WHA Int. Task Request` | codeunit | 50655 | `app/src/Integration/codeunits/IntTaskRequest.Codeunit.al` |
| `WHA Int. Task Confirm` | codeunit | 50656 | `app/src/Integration/codeunits/IntTaskConfirm.Codeunit.al` |
| `WHA Int. HU Received` | codeunit | 50657 | `app/src/Integration/codeunits/IntHUReceived.Codeunit.al` |
| `WHA Int. HU Shipped` | codeunit | 50658 | `app/src/Integration/codeunits/IntHUShipped.Codeunit.al` |
| `WHA Demo Integration` | codeunit | 50659 | `app/src/Integration/codeunits/DemoIntegration.Codeunit.al` |
| `WHA Int. Receipt Release` | codeunit | 50664 | `app/src/Integration/codeunits/IntReceiptRelease.Codeunit.al` |
| `WHA Int. Shipment Release` | codeunit | 50665 | `app/src/Integration/codeunits/IntShipmentRelease.Codeunit.al` |
| `WHA Int. Inventory Adjust` | codeunit | 50666 | `app/src/Integration/codeunits/IntInventoryAdjust.Codeunit.al` |
| `WHA Int. Count Request` | codeunit | 50667 | `app/src/Integration/codeunits/IntCountRequest.Codeunit.al` |
| `WHA Int. Receipt Completed` | codeunit | 50668 | `app/src/Integration/codeunits/IntReceiptCompleted.Codeunit.al` |
| `WHA Int. Shipment Completed` | codeunit | 50669 | `app/src/Integration/codeunits/IntShipmentCompleted.Codeunit.al` |
| `WHA Int. Count Result` | codeunit | 50670 | `app/src/Integration/codeunits/IntCountResult.Codeunit.al` |
| `WHA Int. Stock Position` | codeunit | 50671 | `app/src/Integration/codeunits/IntStockPosition.Codeunit.al` |
| `WHA HU Stock By Location` | query | 50672 | `app/src/Integration/queries/HUStockByLocation.Query.al` |
| `WHA Int. Message Runner` | codeunit | 50660 | `app/src/Integration/codeunits/IntMessageRunner.Codeunit.al` |
| `WHA Int. Retention` | codeunit | 50661 | `app/src/Integration/codeunits/IntRetention.Codeunit.al` |
| `WHA Int. Reten. Sub.` | codeunit | 50662 | `app/src/Integration/codeunits/IntRetenSub.Codeunit.al` |
| `WHA Int. Appl. Area Setup` | tableextension | 50650 | `app/src/Integration/tableextensions/IntApplAreaSetup.TableExt.al` |
| `WHA Integration Setup` | page | 50650 | `app/src/Integration/pages/IntegrationSetup.Page.al` |
| `WHA Integration Messages` | page | 50651 | `app/src/Integration/pages/IntegrationMessages.Page.al` |
| `WHA Integration Message Card` | page | 50652 | `app/src/Integration/pages/IntegrationMessageCard.Page.al` |
| `WHA API Integration Message` | page | 50653 | `app/src/Integration/pages/APIIntegrationMessage.Page.al` |
| `WHA API Demo Integration` | page | 50654 | `app/src/Integration/pages/APIDemoIntegration.Page.al` |
| `WHA Integration Tests` | codeunit | 51002 | `test/src/codeunits/IntegrationTests.Codeunit.al` |
| `WHA Int Activities Cue` | tableextension | 50651 | `app/src/Integration/tableextensions/IntActivitiesCue.TableExt.al` |
| `WHA Int Activity Provider` | enumextension | 50651 | `app/src/Integration/enumextensions/IntActivityProvider.EnumExt.al` |
| `WHA Int Activity Cues` | codeunit | 50663 | `app/src/Integration/codeunits/IntActivityCues.Codeunit.al` |
| `WHA Int Activities` | pageextension | 50651 | `app/src/Integration/pageextensions/IntActivities.PageExt.al` |

All in namespace `WarehouseAdvanced.Integration`, from the reserved block `50650..50699`.
Core changed only by gaining a `WHA Feature` enum value.

## The dispatch — why a wrong guess is cheap

`WHA Int. Message Type` is an **extensible enum that implements `WHA IIntMessageHandler`**, with
`WHA Int. Unhandled Message` as its `DefaultImplementation`. Each value binds its own handler:

```
WHAHandlingUnitReceived   → WHA Int. HU Received     (inbound)
WHAWarehouseTaskRequest   → WHA Int. Task Request    (inbound)
WHAWarehouseTaskConfirmed → WHA Int. Task Confirm    (outbound)
WHAHandlingUnitShipped    → WHA Int. HU Shipped      (outbound)
```

The interface has two methods, which is the whole contract a message type has to satisfy:

| Method | Meaning |
|---|---|
| `HandleInbound` | Apply this message to our data. Raise an error to reject it |
| `CollectOutbound` | Add outbox messages for anything the partner has not been told about |

The spine never branches on message type. `Process` resolves the handler from the enum;
`SweepOutbound` walks **every** ordinal of the enum and asks each one to collect. So:

- **Adding a message type** = one `enumextension` value + one codeunit implementing two methods. No
  existing object is touched, including by a dependent app that we do not ship.
- **Changing a payload shape** = editing one handler. The spine, the API, the retry behaviour, the
  duplicate rules and the audit trail are untouched.
- **A type nobody handles** fails with *"Nothing in this app knows how to apply a message of type
  X"* rather than being silently dropped — that is the default implementation earning its place.

There are **no event publishers**, per the app's standing rule. Outbound messages are produced by a
**sweep**, not by a hook in the directed-work or handling-unit code: those features do not know this
one exists. It also means outbound production is idempotent and restartable, and that a message
missed while the feature was off is picked up the next time the sweep runs.

## Message shapes — the guesses

All bodies are JSON objects. Dates are `YYYY-MM-DD`; date-times are ISO 8601.

### Inbound — `WHAWarehouseTaskRequest`

```json
{
  "taskType": "WHAPick",
  "description": "Pick for order 4711",
  "locationCode": "BLUE",
  "fromBinCode": "B-01-0001",
  "toBinCode": "STAGE-01",
  "handlingUnitNumber": "HU000042",
  "itemNumber": "1896-S",
  "variantCode": "",
  "quantity": 12,
  "priority": 10,
  "dueDate": "2026-08-20",
  "release": true
}
```

`locationCode` is required, and either `handlingUnitNumber` or `itemNumber` must be present, or the
message is refused with nothing created. `taskType` is the enum value name; an unknown one is named
back in the error.

**Whether the task reaches the floor is a decision, not a fixed behaviour.** It was the one place a
guess would have been invisible: a partner that sends work to be done and a partner that sends work
to be checked look identical in the payload. So:

| | |
|---|---|
| `Release requested work` in the setup | The standing policy for this company |
| `"release"` in the message | Overrides it, in either direction, for that message only |
| Neither says anything | Released — the commoner arrangement, and the one that fails loudly |

Completeness is checked by the handler itself, **not** by the release that follows it. That matters:
when work is held rather than released, a request with no location is still refused, instead of
quietly becoming a draft nobody can act on.

> `Release tasks automatically` on the **directed work** setup is a warehouse-wide policy and wins:
> with it on, a task reaches the floor as it is created, whatever this feature asked for. Holding
> requested work for review means turning that off as well.

### Inbound — `WHAHandlingUnitReceived`

```json
{
  "sscc": "380123456789012340",
  "description": "Euro pallet - electronics",
  "locationCode": "BLUE",
  "binCode": "",
  "lines": [
    { "itemNumber": "1896-S", "variantCode": "", "quantity": 6, "lotNumber": "", "serialNumber": "" }
  ]
}
```

**The unit is numbered by this app**, from the handling unit feature's number series. The partner's identifier
stays on the message as `External Id`; it is not written onto the handling unit. If the customer
needs the partner's own pallet ID stored on the unit and searchable, that is a field on
`WHA Handling Unit` and a decision for the register — not something to invent here.

### Outbound — `WHAWarehouseTaskConfirmed`

Written for every task that reaches *Completed*. `External Id` is the task number.

`quantityHandled` is what the operator actually moved and `quantityOutstanding` the difference — a
job completed short reports both, with `shortReason` saying why. **This is the only way the partner
system learns about a shortfall**, so a partner that ignores those three fields will believe every
job was done in full.

```json
{
  "number": "WT000012", "taskType": "WHAPick", "status": "WHACompleted",
  "description": "...", "locationCode": "BLUE", "fromBinCode": "B-01-0001", "toBinCode": "STAGE-01",
  "handlingUnitNumber": "HU000042", "itemNumber": "1896-S", "variantCode": "",
  "quantity": 12, "quantityHandled": 4, "quantityOutstanding": 8, "shortReason": "WHANotEnough",
  "unitOfMeasureCode": "PCS", "assignedToUserId": "MARK",
  "startedDateTime": "2026-08-19T09:12:44Z", "completedDateTime": "2026-08-19T09:31:02Z"
}
```

### Outbound — `WHAHandlingUnitShipped`

Written for every handling unit whose status is *Shipped*, with its contents as they left.
`External Id` is the unit number.

```json
{
  "number": "HU000042", "sscc": "380123456789012340", "description": "...",
  "locationCode": "BLUE", "binCode": "", "parentNumber": "", "status": "WHAShipped",
  "lines": [ { "lineNumber": 10000, "itemNumber": "1896-S", "variantCode": "", "description": "...",
               "quantity": 6, "unitOfMeasureCode": "PCS", "lotNumber": "", "serialNumber": "" } ]
}
```

## Segment 3 — the message set, widened by analogy

Segment 1 shipped four message types and said plainly that at least one more would be needed and
nobody knew which. Segment 3 is the attempt to find out **without** a customer fact, by reading a
different interface that already works.

### Where the evidence came from

A separate, unrelated connector integrates Business Central with a external warehouse execution
system. It is in production, it is documented, and its integration types are a real answer to the
question *what does a BC-side warehouse interface actually have to carry*. Seventeen of them exist.
They are not this customer's contract, and nothing here should be read as if they were — but they
are much better than the blank page segment 1 was written against.

Those seventeen are recorded as candidate rows in
[gap-analysis.md](../gap-analysis.md), marked **evidence by analogy**.

### The direction flips, and that is the whole insight

In that connector, **Business Central is the host** and the warehouse system is external: BC pushes
a receipt out to the warehouse, and the warehouse tells BC what it received.

Here the arrangement is inverted. **This app is the warehouse, inside BC.** Every message therefore
turns around:

| There | Here |
|---|---|
| BC sends a warehouse receipt to the warehouse system | The partner asks **us** to release a receipt to the floor |
| The warehouse system reports the lines it received | **We** report that the receipt is put away |
| BC sends item and unit-of-measure master data out | **Nothing.** Both ends are the same database |
| BC pulls inventory adjustments in | The partner sends **us** an adjustment |
| BC pulls a count session in from the warehouse | **We** report what our own count found |

The third row is the one worth pausing on. Master-data synchronisation is roughly a fifth of that
connector's object count, and here it is **not a gap and not a feature** — it is a consequence of
running in the same database as the items. A capability register that ranks by effort spent
elsewhere would have put it near the top.

### The twelve types

| Type | Direction | What it does |
|---|---|---|
| `WHAHandlingUnitReceived` | in | Creates a handling unit and its contents |
| `WHAWarehouseTaskRequest` | in | Creates one warehouse task, and may name the lot or serial it is for |
| `WHAWarehouseReceiptRelease` | in | Raises put-away work for a standard warehouse receipt |
| `WHAWarehouseShipmentRelease` | in | Raises pick work for a standard warehouse shipment |
| `WHAInventoryAdjustment` | in | Corrects stock through the shared posting engine |
| `WHACountRequest` | in | Raises a count sheet for a location and fills it |
| `WHAWarehouseTaskConfirmed` | out | One completed task, and what was short |
| `WHAHandlingUnitShipped` | out | One despatched handling unit |
| `WHAWarehouseReceiptDone` | out | A receipt whose put-away work is finished |
| `WHAWarehouseShipmentDone` | out | A shipment whose pick work is finished |
| `WHACountResult` | out | A closed count sheet and what it found |
| `WHAStockPosition` | out | One statement per location per day, of what is on handling units |

### Addressed by identity, not by schema

Three of the four new inbound types **read no payload at all.** The receipt release, the shipment
release and the count request each take their subject from the message's `External Id` — the
receipt number, the shipment number, the location code — and the body may be empty.

That is deliberate, and it is the segment's main design decision. Every payload shape in this
feature is a guess; a message that needs no payload cannot have a wrong one. It also comes free
with the idempotency the spine already had, because `External Id` is exactly what the duplicate
check reads: releasing warehouse receipt `WR-1001` twice is refused by the same rule that refuses a
duplicated task request.

Only the inventory adjustment has to carry a body, because item, quantity and location cannot be
recovered from an identifier. Six fields, and no more than six.

### What each new type actually does

- **Release a receipt or a shipment** — calls `WHA Task Source Mgt.`, the same entry point the
  action on the warehouse document uses. The partner system pressing the button remotely and a
  person pressing it on the document run identical code, which is why this needed no new task
  logic at all.
- **Inventory adjustment** — builds a `WHA Posting Request` and hands it to `WHA Posting Mgt.`
  with the method named in the integration setup. What reaches the ledger is therefore a
  *configuration* question, exactly as it is for counting and quality hold: record nothing, write
  a journal line for somebody to review, or post straight through. The default is the middle one,
  and the argument is in [inventory-posting.md](../inventory-posting.md).
- **Count request** — creates a count sheet and fills it through the counting feature's own
  selection. It refuses when counting is switched off rather than creating an orphan sheet.
- **Receipt and shipment completed** — report a document once, and only when **no work against it
  is still open**. A half-picked shipment says nothing. The rule is deliberately not "the last
  task completed", because a task cancelled after the fact would otherwise leave a document that
  never gets reported.
- **Count result** — reports a sheet when it **closes**, not when it is counted, because closing
  is the moment a difference stops being an observation.
- **Stock position** — one statement per location per day. It counts **what this app recorded on
  handling units** and nothing else. It is not a reading of the item ledger, and on a warehouse
  that holds stock this app never put on a unit, the two will disagree. Sending it is how that
  disagreement gets noticed, which is the whole purpose of a reconciliation message.

### What it is still not

- **Still no transport.** Twelve types, no URL, no credential, no token. The partner posts into an
  API page and collects from the outbox, exactly as in segment 1.
- **No EDI.** Despatch advice, orders and receiving advice are absent, and mapping to a standard
  document format is a different problem from carrying a message.
- **No automation control.** Conveyors, sorters, cranes and vehicles need latencies and failure
  semantics a message log does not have.
- **Every payload is still a guess** — a smaller and better-informed one, from a system that is
  not this customer's.

## Failure handling

`Process` runs the handler through `WHA Int. Message Runner`, a codeunit with
`TableNo = "WHA Integration Message"`. That is deliberate and is the only reason the failure
behaviour works: a `Codeunit.Run` that errors **rolls back everything the handler did**, so a
receipt that creates a unit and then fails on its third line leaves no unit behind. The error text
is then written onto the message in the outer transaction.

| | |
|---|---|
| Success | `Status` → Processed, `Processed At` stamped, `Error Message` cleared |
| Failure | `Status` → Failed, `Error Message` set from `GetLastErrorText`, `Retry Count` + 1, all data changes rolled back |
| Retry | The queue run tries failed messages again while `Retry Count` is below `Max Retry Count` |

A message that has not been dealt with **cannot be deleted** — it has to be cancelled, which keeps
the record that it arrived. That is the difference between an audit trail and a log.

## Running it

| Path | What runs |
|---|---|
| Job queue | Codeunit `WHA Int. Message Mgt.` — its `OnRun` processes the inbound queue, then fills the outbox |
| UI | *Integration messages* → **Process all waiting**, **Fill the outbox**, or per-message **Process** / **Acknowledge** / **Cancel** |
| API | `POST` a message, then `process`, `acknowledge` or `cancel` as bound actions |

There is no scheduled job queue entry created on install. Whether this runs every minute or on
demand depends on volumes nobody has measured yet — see below.

## Role centre activities

This feature contributes its own tiles to the warehouse role centre: **messages waiting and messages that failed**. Four objects do it,
all of them in this feature's own folder — a `tableextension` adding the cue fields, an `enumextension`
registering the provider, a codeunit that counts, and a `pageextension` that puts the fields on the cue
part and writes the returned counts back.

**The foundation names none of them.** The seam, and why it is shaped this way, is in
[../FEAT-CORE-001-Foundation/technical-documentation.md](../FEAT-CORE-001-Foundation/technical-documentation.md).

The count runs in a read-only background session and its first line asks whether this feature is
switched on. A switched-off feature adds **nothing** rather than a zero, so its tiles never appear.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHAIntegration` bound to
`WHA Int. Feature Setup` (guided setup step 40); `Application Area Setup` gained `WHA Integration`
through this feature's own tableextension; the app-area subscriber sets it from `Enabled` with
`SkipOnMissingLicense`/`SkipOnMissingPermission` both `true`; the setup page is `ApplicationArea =
All` while the message pages carry `WHAIntegration`. Every write path **and every bound action** on
the API page calls `CheckEnabled`, because application areas do not reach the API.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Integration` | `integration` | `WHA API Integration Message` | read, create, modify, and run process / acknowledge / cancel — **not delete** |
| `Warehouse Advanced - Demo Integration` | `demoIntegration` | `WHA API Demo Integration` | run `importDemoData` only |

Delete is withheld on purpose: an agent tidying up an inbox is exactly the failure mode this feature
exists to prevent. Agent instructions:
[../agent-instructions/WarehouseAdvanced-Integration.md](../agent-instructions/WarehouseAdvanced-Integration.md)
and [../agent-instructions/WarehouseAdvanced-Demo-Integration.md](../agent-instructions/WarehouseAdvanced-Demo-Integration.md).

## Demo data

`WHA Demo Integration` seeds five messages under fixed external identifiers `DEMO-INT-*`: a receipt
waiting to be applied, a work request that is applied, a request that is cancelled, a malformed
request that fails **with a real error message**, and an outbound confirmation waiting to be
collected. Between them they cover both directions and all four statuses.

The sample messages are driven through the **real** spine — `CreateInbound`, `Process`, `Cancel` —
never by writing `Status` directly, so the failure example shows an error the app genuinely
produces. It loads what it can: on a company with no location or item, the request messages fail
rather than being skipped, which is itself an honest demonstration.

`Import()` also builds the `WHA-INT` RapidStart package, containing `WHA Integration Message` only.

## Tests

`WHA Integration Tests` (codeunit 51002), 20 tests. Three cover retention: the message log is offered
to the framework, the retention clock runs from when a message was processed, and a policy shorter
than the minimum this feature insists on is refused. The other 17: payload round-trip; arrival stamping; unknown
type and outbound-only type refused with readable reasons; a request creating and releasing a task
and pointing at it; incomplete and unknown-type requests refused with nothing left behind; the same
request applied only once; a receipt creating a unit with its contents; the outbound sweep reporting
a completed task exactly once across repeated sweeps; the confirmation payload carrying the task;
acknowledge closing an outbound message; process and acknowledge refusing each other's direction;
cancel keeping the message; a waiting message refusing deletion; auto-process on arrival; requested
work held when the setup says so and released when it does not, with a message overriding the
standing setting in both directions; a request with no location refused and leaving nothing behind;
and demo idempotency.

The release tests switch off `Release tasks automatically` on the directed work setup first, so that
a released task proves *this* feature released it rather than the task feature doing so on insert.

## What has to come from the customer

Everything here is replaceable once these are known. In rough order of how much they change:

1. **The real message set.** Which events cross the boundary at all — is stock counted on our side
   or theirs, who owns the item master, does anything ask for a *cancellation* of work already sent?
   And does requested work arrive ready to do, or to be checked first? The setting exists so that
   answer is configuration rather than code, but somebody still has to give it.
2. **The real payload shapes**, including the identifiers the partner uses. Every field name above
   is provisional.
3. **The transport and its direction.** Does the partner post to us, do we post to them, is there a
   file drop or a queue in between? Only the *outbox* half is assumed here, and only because it is
   the half that survives being wrong.
4. **Volumes.** Messages per hour decides whether this runs on a job queue every minute, whether
   `Process` stays synchronous, and whether the message table needs a retention policy.
5. **The cutover model.** A parallel run means both systems hold stock at once, and this feature
   grows a reconciliation problem that a big-bang cutover does not have. That decision changes this
   feature more than any other.

## Retention — the one table that grows on its own

Every other table in this app is bounded by a business event: a wave closes, a count sheet is filed, a
hold is released. **The message log is not.** A partner sending a thousand messages a day adds a
thousand rows a day, each carrying a payload blob, and nothing in the business process ever removes
one. On a per-tenant extension against BC online that is a bill, and eventually a limit.

The answer is deliberately **not** a clean-up of this feature's own. A bespoke one would have needed a
setup field, a scheduler, a batch size, a log and a permission — all of which the platform already
has, with a UI and an audit trail this feature would only imitate badly.

`WHA Int. Retention` offers `WHA Integration Message` to the standard **retention policy** framework
through a subscriber to `Reten. Pol. Allowed Tables.OnRefreshAllowedTables`. From then on an
administrator sets a policy on the standard *Retention Policies* page, alongside every other one, and
Business Central's own job does the deleting.

Three choices inside that registration are this feature's, and each is a judgement:

- **The clock runs from `Processed At`, not from `Received At`.** A message that sat unprocessed for a
  month has not been *kept* for a month — nobody has read it yet. Ageing from arrival would delete the
  backlog fastest at exactly the moment somebody started looking at it.
- **The default filter covers processed messages only.** A failed or cancelled message is evidence,
  and a policy that swept it up by default would remove the record of the failure along with it. An
  administrator can widen the filter; they have to mean it.
- **A mandatory minimum of seven days.** The framework refuses any policy shorter. This log is what an
  argument with a partner is settled from, and a policy that could clear it within a day would take
  the evidence away before anybody noticed there was a dispute.

Nothing is registered as *enabled*: the table becomes eligible for a policy, and no policy exists until
somebody creates one. A fresh installation deletes nothing.

## Not done

- **No transport.** No HTTP, no credential store, no endpoint master data. Deliberate: see above.
- **No archiving, only deletion.** A retention policy removes expired messages; nothing copies them
  anywhere first. A warehouse that has to keep a year of interface traffic for audit needs to export
  it before the policy runs, and nothing reminds them.
- **No policy is created for you.** The table is offered to the framework; an administrator still has
  to set the period. Until they do, the log grows exactly as it did before — this makes the clean-up
  *possible*, not automatic.
- **No master-data message, and none is coming.** Items and units of measure are in the same
  database as this app. What an external warehouse system needs synchronised, this one can read.
- **No EDI, and no automation control.** Both are named in the register; neither is a message type.
- **No cancellation of already-sent work.** A partner withdrawing a task it requested has no
  message; today someone cancels the task in the UI.
- **Getting-started in the customer language** — the language has not been confirmed.
