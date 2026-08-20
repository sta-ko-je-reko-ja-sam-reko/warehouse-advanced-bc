# Telemetry

What this app tells the partner about itself, and — more importantly — what it will never tell them.
This is not a feature document: nothing here is switched on, has a wizard step, or appears in the
guided setup list. It is the third piece of shared machinery, alongside
[inventory-posting.md](inventory-posting.md) and [warehouse-registration.md](warehouse-registration.md).

## The problem it exists to remove

The app ships **five scheduled entry points** — replenishment, wave templates, slotting, labour
management and analytics — plus the integration message runner. All of them are designed to be pointed
at by a job queue entry and to run with nobody watching.

Until this, they said nothing. A run that did nothing every night for a month looked exactly like a run
that was working. The only trace of a failure was the error text on the job queue entry, which nobody
reads until somebody notices the stock is wrong.

## What is emitted

Two events, through Business Central's own `Feature Telemetry` codeunit, so it lands in the partner's
Application Insights next to everything else and is grouped by feature like everything else.

| Event | When | Dimensions |
|---|---|---|
| `WHA0001` — scheduled run finished | Every completed scheduled run | The run's name, and how many things it handled |
| `WHA0002` — scheduled run did nothing | A run that stopped before doing anything | The run's name, and a fixed phrase saying why |

**Zero is a finding, not a failure**, and it is reported as a number rather than by staying silent.
Slotting is the one that distinguishes the two: a location with no movement history reports `WHA0002`
with a reason, rather than a finished run that handled nothing.

## What is never emitted

Telemetry leaves the customer's tenant. The System Application's own documentation on this codeunit is
blunt about it — *only system metadata is to be emitted* — and this module takes that literally.

**No item number, lot number, serial number, document number, bin code, location code, quantity of
stock, or user name is emitted by this app, ever.**

That is guaranteed by the **shape of the procedures rather than by care at the call sites**: there is no
parameter on `LogScheduledRun` or `LogRunSkipped` through which any of those could be passed. A caller
that wanted to leak one would have to change this module first, which is a code review rather than an
oversight. The `Reason` on a skipped run is a fixed phrase held as a `Label` in the calling codeunit —
never anything read out of the data.

The count is formatted with `Format(Handled, 0, 9)` — the invariant format. A count formatted for the
session's language would sort and parse differently depending on who happened to run the job.

## Testing

`WHA Telemetry Tests` asserts the dimensions rather than the emitting: the builders are separate
procedures precisely so that what leaves the tenant can be checked without a telemetry endpoint to read
back from. One test asserts the **dimension count** is exactly two, so a future dimension cannot be
added without a test failing and somebody deciding it is allowed to leave.

What is not tested is whether Application Insights receives any of it. That needs a running container
and a configured endpoint, and like everything else in this app, **none of it has ever run**.

## Not done

- **Feature uptake.** How much of this app a warehouse actually uses is the most valuable thing a
  partner could learn, and it is not emitted. `Feature Telemetry.LogUptake` is the right mechanism, but
  there is no single place that knows *which* feature was switched on: `WHA Feature Mgt.` is generic and
  each of the fourteen setup pages calls it without saying who it is. Wiring it means touching all
  fourteen, which belongs in its own change rather than being smuggled into this one.
- **The guards say nothing.** The refusals added for location configuration, open work, warehouse
  employees, item tracking and expiry are all silent to telemetry. A warehouse whose operators hit the
  same refusal fifty times a day is telling the partner something, and nobody is listening.
- **No errors are logged.** `Feature Telemetry.LogError` exists and is not called. A scheduled run that
  throws is still only visible on the job queue entry.
- **Nothing measures duration.** How long a run takes is the first thing anybody asks when one starts
  timing out.
