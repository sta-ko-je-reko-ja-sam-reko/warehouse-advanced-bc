# FEAT-DOCK-001 - Dock and yard

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Standard Business Central has no dock door, no appointment and no yard: a receipt or a shipment
> knows the location it happens at and nothing about the physical door it happens through. That is
> the gap claimed here. It is also the one feature in the catalogue with **no dependency on anything
> else in the app** — nothing it records is derived from handling units, tasks or waves — which is
> why it could be built last and could equally have been built first.

## Business process

A vehicle visit has four moments worth recording, and standard BC records none of them.

1. A **booking** promises a vehicle a door at a time. The door is chosen by a swappable strategy when
   nobody names one, and no two bookings whose slots overlap can hold the same door.
2. **Arrival** is the gate: the vehicle is on site, and the trailer is parked in a named yard position
   so that somebody can find it again.
3. **Going to the door** takes the vehicle off the yard and puts it on the door, giving the yard
   position back.
4. **Departure** ends the visit and frees everything the vehicle held.

A booking that is called off is cancelled rather than deleted, and a visit that actually happened
cannot be deleted at all.

### Delivered so far

**Segment 1** — the door and yard-position masters, the appointment with its four timestamps, two
door-selection strategies, slot clash detection, and yard occupancy.

## What the times are for

The four timestamps are the point of the feature, not a by-product of it. `Arrived At`,
`At Door At` and `Departed At` are what `FEAT-KPI-001` reads to answer how long a vehicle waited and
how long the whole visit took — the two numbers a haulier and a warehouse argue about, and the two
that nothing in standard BC can produce.

`Expected At` is kept apart from `Arrived At` on purpose: the difference between them is lateness,
and a system that overwrites the promise with what happened cannot measure it.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Dock Setup` | 50450 | Single-record feature setup |
| `WHA Dock Door` | 50451 | One door, at one location |
| `WHA Yard Position` | 50452 | One place a trailer can stand |
| `WHA Dock Appointment` | 50453 | One vehicle visit, promised and then recorded |

### `WHA Dock Door`

Keyed by location and code, because a door code only has to be unique within its own site. `Takes`
is inbound, outbound or both, and a booking cannot be given a door that does not take its direction.
`Waiting position` names where vehicles for this door normally wait — a suggestion offered at
check-in, never a rule.

### `WHA Yard Position`

Keyed by location and code. `Occupied By Appt. No.` is **the current state, not history**: it is
filled when a trailer is parked and cleared when it goes to a door, leaves, or the booking is called
off. That is what makes the yard list answer "where is that trailer" rather than "where was it".

### `WHA Dock Appointment`

| Field | Notes |
|---|---|
| `No.` | From this feature's own number series `WHA-DOCK` |
| `Direction`, `Dock Door Code`, `Slot Minutes` | What was promised, and what it occupies |
| `Carrier Name`, `Trailer No.`, `Reference` | What turns up, and what it is here for |
| `Expected At` | The promise. Lateness is measured against it |
| `Status` | Booked, arrived, at the door, departed, cancelled |
| `Arrived At`, `At Door At`, `Departed At` | What actually happened, and the input to the KPIs |
| `Yard Position Code` | Where the trailer is standing **now** |
| `Booked By User ID`, `Created At` | Who promised it, and when |

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Dock Setup` | table | 50450 | `app/src/DockYard/tables/DockSetup.Table.al` |
| `WHA Dock Door` | table | 50451 | `app/src/DockYard/tables/DockDoor.Table.al` |
| `WHA Yard Position` | table | 50452 | `app/src/DockYard/tables/YardPosition.Table.al` |
| `WHA Dock Appointment` | table | 50453 | `app/src/DockYard/tables/DockAppointment.Table.al` |
| `WHA Dock Direction` | enum | 50450 | `app/src/DockYard/enums/DockDirection.Enum.al` |
| `WHA Door Direction` | enum | 50451 | `app/src/DockYard/enums/DoorDirection.Enum.al` |
| `WHA Appointment Status` | enum | 50452 | `app/src/DockYard/enums/AppointmentStatus.Enum.al` |
| `WHA Door Selection` | enum | 50453 | `app/src/DockYard/enums/DoorSelection.Enum.al` |
| `WHA IDockAppointment` | interface | — | `app/src/DockYard/interfaces/IDockAppointment.Interface.al` |
| `WHA IDoorSelection` | interface | — | `app/src/DockYard/interfaces/IDoorSelection.Interface.al` |
| `WHA Dock Mgt.` | codeunit | 50450 | `app/src/DockYard/codeunits/DockMgt.Codeunit.al` |
| `WHA Dock Appt. Logic` | codeunit | 50451 | `app/src/DockYard/codeunits/DockApptLogic.Codeunit.al` |
| `WHA Dock Feature Setup` | codeunit | 50452 | `app/src/DockYard/codeunits/DockFeatureSetup.Codeunit.al` |
| `WHA Dock App Area Sub.` | codeunit | 50453 | `app/src/DockYard/codeunits/DockAppAreaSub.Codeunit.al` |
| `WHA Demo Dock` | codeunit | 50454 | `app/src/DockYard/codeunits/DemoDock.Codeunit.al` |
| `WHA Door First Free` | codeunit | 50455 | `app/src/DockYard/codeunits/DoorFirstFree.Codeunit.al` |
| `WHA Door Least Busy` | codeunit | 50456 | `app/src/DockYard/codeunits/DoorLeastBusy.Codeunit.al` |
| `WHA Dock Appl. Area Setup` | tableextension | 50450 | `app/src/DockYard/tableextensions/DockApplAreaSetup.TableExt.al` |
| `WHA Dock Setup` | page | 50450 | `app/src/DockYard/pages/DockSetup.Page.al` |
| `WHA Dock Doors` | page | 50451 | `app/src/DockYard/pages/DockDoors.Page.al` |
| `WHA Yard Positions` | page | 50452 | `app/src/DockYard/pages/YardPositions.Page.al` |
| `WHA Dock Appointments` | page | 50453 | `app/src/DockYard/pages/DockAppointments.Page.al` |
| `WHA Dock Appointment Card` | page | 50454 | `app/src/DockYard/pages/DockAppointmentCard.Page.al` |
| `WHA API Dock Door` | page | 50455 | `app/src/DockYard/pages/APIDockDoor.Page.al` |
| `WHA API Yard Position` | page | 50456 | `app/src/DockYard/pages/APIYardPosition.Page.al` |
| `WHA API Dock Appointment` | page | 50457 | `app/src/DockYard/pages/APIDockAppointment.Page.al` |
| `WHA API Demo Dock` | page | 50458 | `app/src/DockYard/pages/APIDemoDock.Page.al` |
| `WHA Dock Tests` | codeunit | 51012 | `test/src/codeunits/DockTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.DockYard`, from the reserved block `50450..50499`.

**Core changed in one place**: a `WHA Feature` enum value. The appointment numbering lives on this
feature's own setup, so Core does not know this feature numbers anything.

> The first version of this feature put `Dock Appointment Nos.` on `WHA Warehouse Setup` and created
> the series in the foundation step, which made the foundation step read as *not started* on
> companies that had already finished it. That was the last straw for foundation-owned numbering; it
> now lives here, and the foundation step no longer has anything to be incomplete about.

## Door selection is a decision the warehouse owns

`WHA IDoorSelection` chooses a door when a booking does not name one. **It never decides whether a
door is allowed** — direction, blocking and slot clashes are checked by `WHA Dock Mgt.DoorCanTake`
before a strategy's answer is used, so a strategy cannot put a vehicle somewhere the yard would
refuse, and every strategy obeys the same rules for free.

| Strategy | Chooses | Right when |
|---|---|---|
| **The first free door** (default) | The first usable door in code order | The doors are not equivalent — one end of the building is nearer everything, and drivers learn one route |
| **The least busy door** | The usable door with the fewest bookings that day | The doors are equivalent and the constraint is the people working them |

A third strategy — nearest to the goods, by zone — is the obvious next one and needs nothing from
this app but an `enumextension`.

## Two clash rules, not one

They answer different questions and both are needed:

- **The slot clash** (`Expected At` plus `Slot Minutes`) stops a clash being *planned*. It is
  checked when a door is assigned, and it ignores departed and cancelled bookings.
- **The door check at the moment of use** stops a clash *happening anyway* when the first vehicle
  overruns its slot. Only one appointment can be `At the door` on a door at a time.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHADockYard` bound to
`WHA Dock Feature Setup` (guided setup step 140); `Application Area Setup` gained `WHA Dock Yard`
through this feature's own tableextension; the setup page is `ApplicationArea = All` while the dock
pages carry `WHADockYard`.

**One new number series**, `WHA-DOCK` (`DA000001`..`DA999999`), created by this feature's own guided-setup step when numbering is asked for.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Dock and Yard` | `dockYard` | `WHA API Dock Door` | **read only** |
| `Warehouse Advanced - Dock and Yard` | `dockYard` | `WHA API Yard Position` | **read only** |
| `Warehouse Advanced - Dock and Yard` | `dockYard` | `WHA API Dock Appointment` | read, create and modify — which in practice means **taking a booking** |
| `Warehouse Advanced - Demo Dock and Yard` | `demoDockYard` | `WHA API Demo Dock` | run `importDemoData` only |

Booking is the one thing in this feature an agent can usefully do, because it is the part that
happens on the telephone. **Checking a vehicle in, putting it on a door and sending it away are
bound actions and no action is exposed**: those three are statements about the physical world, and
nothing that cannot see the yard should be making them. The status and the timestamps are read-only
through the API for the same reason.

Doors and yard positions are read-only to agents: they are master data, and a door invented by an
agent is a door that does not exist.

## Demo data

`WHA Demo Dock` seeds three doors (one inbound, one outbound, one that takes both), two yard
positions, and two bookings at the first location the company has — one of which is driven all the
way through arrival, the door and departure so that there is a finished visit with real timestamps
for the analytics feature to read. Idempotent: doors and positions are keyed, and a booking is
recognised by the reference it carries. `Import()` builds the `WHA-DOCK` RapidStart package.

## Tests

`WHA Dock Tests` (codeunit 51012), 15 tests: a door is chosen when nobody names one; a door only
takes the direction it is for; a blocked door takes nothing and a booking with no usable door is
still taken; two bookings cannot share a door in overlapping slots while a later slot on the same
door is fine; checking in parks the trailer and fills the yard position; a yard position holds one
trailer; going to the door gives the position back; two vehicles cannot stand at one door;
departing frees the yard and keeps the times; a visit that happened cannot be deleted; a booking
nobody kept can be called off; a waiting vehicle needs somewhere to wait when the yard says so; the
least busy strategy spreads the traffic; and demo idempotency.

## Not done

- **Nothing connects a visit to what was on the vehicle.** No receipt, no shipment, no handling
  unit. A booking carries a free-text `Reference` and that is all, which is why the analytics feature
  cannot measure true dock-to-stock — see [../FEAT-KPI-001-Analytics/technical-documentation.md](../FEAT-KPI-001-Analytics/technical-documentation.md).
- **No capacity or labour model.** A slot is a door and a length of time. It does not know how many
  people are on shift, how long the load actually takes, or that three vehicles arriving at once is
  a problem even on three different doors.
- **No calendar or opening hours.** Bookings can be made at three in the morning on a Sunday.
- **No self-service booking for carriers.** The API can take a booking, so the wiring is there, but
  nothing authenticates or rate-limits an outside party.
- **No gate screen.** Check-in is a back-office action, not a handheld flow, and `FEAT-RF-001` does
  not know about the yard.
- **No trailer register.** `Trailer No.` is text, so a trailer has no history across visits.
- **Getting-started in the customer language** — the language has not been confirmed.
