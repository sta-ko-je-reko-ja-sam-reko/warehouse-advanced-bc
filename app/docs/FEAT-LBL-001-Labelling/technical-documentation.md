# FEAT-LBL-001 - Labelling

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> Segment 1 deliberately does the one part of this feature that is a **standard rather than a
> guess**: the GS1 code. Label templates and printer routing — the parts that depend entirely on
> what hardware this customer has and what their partners demand — are not started.

## Business process

`FEAT-HU-001` gave every handling unit an `SSCC` field and left it empty, noting that *"generating a
valid GS1 check digit belongs to `FEAT-LBL-001`"*. This is that.

A handling unit needs a code that goes on its label. Two kinds of warehouse need two different
things from it:

- One that ships to trading partners needs an **SSCC** — an 18-digit GS1 code whose last digit is a
  checksum, so a partner's scanner can tell a misread from a real code.
- One that only moves pallets around its own building needs a **licence plate** — something short
  and sequential that means nothing to anybody else and does not require a GS1 subscription.

Both are here, chosen in setup. A code is taken, put on the unit, and never taken back, because by
then it is printed on a sticker.

### Delivered so far

**Segment 1** — code generation in two formats, validation, and assignment to a handling unit.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Label Setup` | 50600 | Single-record feature setup, including the counter |

**This feature owns no transactional table.** The code it produces lives on
`WHA Handling Unit.SSCC`, which already existed. Adding a "label" record would have created a second
place where a unit's code is written down, and the pallet only wears one sticker.

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Format` | `WHA Label Code Format` — SSCC or sequential licence plate |
| `GS1 Company Prefix` | The prefix GS1 issued to this company. **No default** — see below |
| `Extension Digit` | The first digit of an SSCC, 0–9, the company's to choose |
| `Last Serial Reference` | The counter. Not editable, and it only ever counts up |

**The company prefix ships blank on purpose.** There is no safe default for a number GS1 issues to
one company: a plausible-looking placeholder would produce codes that scan, validate, and identify
somebody else. Generation errors until it is filled in.

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Label Setup` | table | 50600 | `app/src/Labelling/tables/LabelSetup.Table.al` |
| `WHA Label Code Format` | enum | 50600 | `app/src/Labelling/enums/LabelCodeFormat.Enum.al` |
| `WHA ILabelCodeFormat` | interface | — | `app/src/Labelling/interfaces/ILabelCodeFormat.Interface.al` |
| `WHA SSCC Format` | codeunit | 50600 | `app/src/Labelling/codeunits/SSCCFormat.Codeunit.al` |
| `WHA Label Feature Setup` | codeunit | 50601 | `app/src/Labelling/codeunits/LabelFeatureSetup.Codeunit.al` |
| `WHA Label App Area Sub.` | codeunit | 50602 | `app/src/Labelling/codeunits/LabelAppAreaSub.Codeunit.al` |
| `WHA Demo Label` | codeunit | 50603 | `app/src/Labelling/codeunits/DemoLabel.Codeunit.al` |
| `WHA Label Mgt.` | codeunit | 50604 | `app/src/Labelling/codeunits/LabelMgt.Codeunit.al` |
| `WHA Sequential Format` | codeunit | 50605 | `app/src/Labelling/codeunits/SequentialFormat.Codeunit.al` |
| `WHA Label Appl. Area Setup` | tableextension | 50600 | `app/src/Labelling/tableextensions/LabelApplAreaSetup.TableExt.al` |
| `WHA Label Setup` | page | 50600 | `app/src/Labelling/pages/LabelSetup.Page.al` |
| `WHA API Label` | page | 50601 | `app/src/Labelling/pages/APILabel.Page.al` |
| `WHA API Demo Label` | page | 50602 | `app/src/Labelling/pages/APIDemoLabel.Page.al` |
| `WHA Labelling Tests` | codeunit | 51005 | `test/src/codeunits/LabellingTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.Labelling`, from the reserved block `50600..50649`.

## A format is a pure function

`WHA ILabelCodeFormat` has three methods, and the important one takes the number rather than
fetching it:

| Method | Meaning |
|---|---|
| `Build(SerialReference)` | The code for **this** number. Same input, same output; builds nothing away |
| `IsValid(Code)` | Could this code have come from this format? |
| `Describe()` | One line, shown on the setup page next to the choice |

Handing out serial references is `WHA Label Mgt.`'s job, not the format's. That split is what lets
the setup page show **an example of the next code without spending it** — somebody checking that
their prefix produces what they expect must not burn label codes doing it. It also makes both
formats testable without touching the database.

`WHA Label Code Format` is an extensible enum, so a customer with their own scheme — a carrier's
tracking format, a legacy plate layout — adds one enum value and one codeunit.

### The check digit

The GS1 modulo-10 checksum: every digit weighted three or one alternately from the **rightmost data
digit**, and the check digit is whatever takes the total to a multiple of ten. It is the one part of
this feature a trading partner will independently verify, so the test anchors it to
**4006381333931** — a real EAN-13 whose check digit is publicly known — rather than to our own
output, which would only prove the code agrees with itself.

### Taking a number

`NextSerialReference` locks the setup record before incrementing, so two people labelling at the
same moment cannot be handed the same number. Two pallets wearing the same code is the worst thing
this feature could do; it is worth a lock.

## Assignment, and what is deliberately not automatic

`AssignTo` puts a code on a handling unit and refuses two cases:

- **A unit that already has a code.** The label is printed and stuck on; issuing a second code makes
  the pallet and the system disagree, and people believe the pallet.
- **A unit that has shipped.** Labelling it achieves nothing but using up a code.

**Codes are never assigned automatically on insert**, and that is a decision rather than an
omission. Doing it would mean `WHA Handling Unit` calling into labelling — a feature reaching
sideways into another, which this app does not do, and which would also mean handling units stopped
working when labelling was switched off. Assignment is therefore explicit: the action on the
handling unit card, or the `assignLabel` API action.

If auto-assignment is wanted later, the right shape is the inverse: handling units gain their own
setup field naming an optional code source, and resolve it through an interface **they** own. That
is a handling-unit segment, not a labelling one.

### The one place this feature touches another

`WHA Handling Unit Card` gains an **Assign label code** action carrying
`ApplicationArea = WHALabelling` and `AccessByPermission = tabledata "WHA Label Setup" = R`, so it
appears only when labelling is enabled *and* the user holds the module. That is the pattern's
prescribed way for a feature to surface a control onto another page.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHALabelling` bound to
`WHA Label Feature Setup` (guided setup step 80); `Application Area Setup` gained `WHA Labelling`;
the app-area subscriber sets it from `Enabled`; the setup page is `ApplicationArea = All` while the
code fields carry `WHALabelling`. The API action calls `CheckEnabled`.

**No number series.** Label codes are counted by this feature's own setup, because a code has to
have a shape GS1 recognises — a `No. Series` cannot express "pad to seventeen digits then compute a
checksum". This is the first feature to number something without the foundation series, and it is
the right exception rather than a shortcut.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Labelling` | `labelling` | `WHA API Label` | read, and run `assignLabel` — **no create, modify or delete** |
| `Warehouse Advanced - Demo Labelling` | `demoLabelling` | `WHA API Demo Label` | run `importDemoData` only |

The functional tool is read-plus-one-action on purpose: the only write worth exposing is "give this
unit a code", and it is irreversible.

## Demo data

`WHA Demo Label` sets a sample GS1 prefix (`0801234`) if none is configured, then labels the
`DEMO-HU-*` units that have no code and have not shipped. Re-running **leaves existing codes
alone** — the idempotency rule here is stronger than "creates nothing new", because relabelling
would silently invalidate a sticker. `Import()` also builds the `WHA-LBL` RapidStart package.

## Tests

`WHA Labelling Tests` (codeunit 51005), 15 tests. Most touch no database at all, because `Build` is
a pure function: the check digit against a published barcode and three hand-worked cases; an
18-digit valid code; the same reference giving the same code twice; the extension digit and prefix
appearing where they should; a tampered check digit, a short code, letters, and an empty code all
refused; a missing prefix and a non-numeric prefix refused; the sequential format; taking a code
using up exactly one number; an example using up none; assignment putting the code on the unit;
refusing to label a unit twice or a shipped unit; and demo re-runs leaving codes alone.

## Not done

- **Label templates and printing.** Nothing renders a label or sends it anywhere. This is the larger
  half of the catalogue entry and needs to know what label stock, what printers and what layouts the
  customer has — none of which is known.
- **Printer routing per zone.** Same reason.
- **GS1-128 barcode content** beyond the SSCC — no application identifiers, no concatenated
  element strings.
- **Automatic assignment.** See above — deliberate, with the intended future shape stated.
- **Codes for anything but handling units.** Cartons from `FEAT-PACK-001` are handling units, so they
  are covered; nothing else is.
- **Getting-started in the customer language** — the language has not been confirmed.
