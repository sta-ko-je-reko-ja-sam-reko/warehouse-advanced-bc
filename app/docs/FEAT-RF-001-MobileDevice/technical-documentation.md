# FEAT-RF-001 - Mobile Device

## Source/legacy reference

N/A (greenfield).

> **Scope note.** Built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register,
> and **not** validated against operators. The plan calls this the feature with a disproportionate
> risk: *"a scanner UI is a different interaction model, not a page set, and it is the feature most
> likely to be judged by operators against what the incumbent already does."* That judgement has not
> happened. What follows is a first take, built early and deliberately thin, so that the step
> sequence can be argued with before anything is built on top of it.
>
> **The step sequence is the guess, and it is isolated behind one interface.** `WHA IRFFlow` is the
> entire handheld contract; the screen holds no rules of its own. A different sequence — more scans,
> fewer, a quantity prompt, a short-pick path — is a new implementation of that interface bound to a
> new `WHA RF Flow` enum value, chosen in setup. No existing object changes.

## Business process

Standard Business Central's client is desktop-shaped: wide pages, many fields, a mouse. A warehouse
operator has one hand, a scanner, and a screen the size of a playing card. This feature is the
screen they actually use:

1. The operator **scans the code on the handheld** to sign in. The device says which part of the
   warehouse they are in.
2. They ask for work. The queue hands them the most urgent job at that location — their own
   unfinished work first — and marks it started.
3. The screen shows **one instruction at a time**: *"Go to bin B-01-0001 and scan it."*
4. They scan their way through the job: the bin they take from, the handling unit (by its number
   **or** the SSCC on its label), the bin they put it in.
5. They **confirm**. The task completes, the handling unit moves to its destination, and the screen
   asks whether they want the next job.
6. If they cannot finish, they **hand it back** and it returns to the queue for somebody else.

### Delivered so far

**Segment 1** — device registration, sign-in, the standard scan-through flow, and the handheld
screen itself.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA RF Setup` | 50100 | Single-record feature setup: enablement and how the flow behaves |
| `WHA RF Device` | 50101 | One registered handheld |

### `WHA RF Device`

| Field | Type | Notes |
|---|---|---|
| `Code` | `Code[20]` | Primary key — the barcode stuck on the device |
| `Description` | `Text[100]` | Which handheld this is, for when it goes missing |
| `Default Location Code` | `Code[10]` | The part of the warehouse it works in. **This is what filters the queue** |
| `Blocked` | `Boolean` | A device out of use cannot be signed in to |
| `Last User ID` / `Last Seen At` | `Code[50]` / `DateTime` | Stamped at sign-in, not editable |

Keys: `PK` on `Code` (clustered), plus `Placement` (`Default Location Code`, `Blocked`).

**The device is not a session.** It records who signed in last, not who is signed in now. Segment 1
keeps the operator's place on the page, in their own session — see "Not done".

### `WHA RF Setup`

| Field | Notes |
|---|---|
| `Enabled` | The feature toggle |
| `Flow` | Which `WHA RF Flow` implementation drives the screen. Ships as *Standard* |
| `Require device registration` | Off lets the screen be tried from a desktop with no device at all |
| `Confirm by scan` | On makes the operator prove where they are standing. Off collapses the job to one tap |
| `Start work automatically` | On marks a job started the moment it is handed over — on a handheld there is nothing between being given work and starting it |

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA RF Setup` | table | 50100 | `app/src/MobileDevice/tables/RFSetup.Table.al` |
| `WHA RF Device` | table | 50101 | `app/src/MobileDevice/tables/RFDevice.Table.al` |
| `WHA RF Step` | enum | 50100 | `app/src/MobileDevice/enums/RFStep.Enum.al` |
| `WHA RF Flow` | enum | 50101 | `app/src/MobileDevice/enums/RFFlow.Enum.al` |
| `WHA IRFFlow` | interface | — | `app/src/MobileDevice/interfaces/IRFFlow.Interface.al` |
| `WHA RF Standard Flow` | codeunit | 50100 | `app/src/MobileDevice/codeunits/RFStandardFlow.Codeunit.al` |
| `WHA RF Feature Setup` | codeunit | 50101 | `app/src/MobileDevice/codeunits/RFFeatureSetup.Codeunit.al` |
| `WHA RF App Area Sub.` | codeunit | 50102 | `app/src/MobileDevice/codeunits/RFAppAreaSub.Codeunit.al` |
| `WHA Demo RF Device` | codeunit | 50103 | `app/src/MobileDevice/codeunits/DemoRFDevice.Codeunit.al` |
| `WHA RF Appl. Area Setup` | tableextension | 50100 | `app/src/MobileDevice/tableextensions/RFApplAreaSetup.TableExt.al` |
| `WHA RF Setup` | page | 50100 | `app/src/MobileDevice/pages/RFSetup.Page.al` |
| `WHA RF Devices` | page | 50101 | `app/src/MobileDevice/pages/RFDevices.Page.al` |
| `WHA RF Device Card` | page | 50102 | `app/src/MobileDevice/pages/RFDeviceCard.Page.al` |
| `WHA RF Handheld` | page | 50103 | `app/src/MobileDevice/pages/RFHandheld.Page.al` |
| `WHA API RF Device` | page | 50104 | `app/src/MobileDevice/pages/APIRFDevice.Page.al` |
| `WHA API Demo RF Device` | page | 50105 | `app/src/MobileDevice/pages/APIDemoRFDevice.Page.al` |
| `WHA RF Tests` | codeunit | 51003 | `test/src/codeunits/RFTests.Codeunit.al` |

All in namespace `WarehouseAdvanced.MobileDevice`, from the reserved block `50100..50149`.
Core changed only by gaining a `WHA Feature` enum value.

## The flow interface — where the guess lives

`WHA IRFFlow` is the whole contract between the screen and the warehouse:

| Method | Meaning |
|---|---|
| `SignIn` | Establish the device; refuse an unknown or blocked one |
| `NextTask` | Hand over the next job at the device's location |
| `FirstStep` | Where this job starts, given what it actually names |
| `Scan` | Check what was scanned against the current step; answer with the next step |
| `Instruction` | The one line the operator reads |
| `Confirm` | Finish the job |
| `HandBack` | Return the job to the queue |

`WHA RF Flow` is an **extensible enum implementing that interface**, with `WHA RF Standard Flow` as
its `DefaultImplementation`, and the setup names which value is in use. So a customer whose operators
work differently gets a new enum value and one codeunit — the screen, the device register, the
enablement and the queue underneath are all untouched. This is the same shape the app uses for
feature setup and for integration message types.

### The standard flow

```
SignIn ──► GetWork ──► [ScanFrom] ──► [ScanUnit] ──► [ScanTo] ──► Confirm ──► GetWork
```

Steps in brackets appear **only when the job names them** — no empty prompts. With
`Confirm by scan` off, every bracketed step is skipped and the job is one tap.

- The handling unit step accepts **either** the unit number **or** the SSCC on its label, because an
  operator scans whichever barcode faces them.
- Scans are compared **case-insensitively and with spaces stripped**. Scanners and people disagree
  about both, and neither should cost an operator a walk.
- A wrong scan **names where to go instead**: *"You scanned B-02-0007. Go to bin B-01-0001."*
- The page holds no rules. Every trigger and action delegates one line to the resolved flow.

## What building this found in the queue beneath it

The plan expected the handheld to test the design of `FEAT-TASK-001`, and it did, immediately.

**Handing back started work left it in limbo.** `Validate_AssignedToUserID` returned an *Assigned*
task to *Released* when its user was cleared, but left an *In progress* one in progress with nobody
holding it — invisible to the queue for ever, since `GetNextForUser` only offers *Released* work and
that operator's own *Assigned* and *In progress* jobs. On the desktop that state is reachable but
odd; on a handheld, "I can't finish this" is a button an operator presses several times a day.

Fixed in `WHA Warehouse Task Logic`: clearing the user on an *In progress* task returns it to
*Released* **and clears `Started At`**, because it is no longer true that anybody started it. Covered
by `HandingBackStartedWorkReturnsItToTheQueue` in the directed work tests as well as through the
flow here.

## Enablement

Per `_patterns/feature-setup-and-toggle.md`: `WHA Feature` gained `WHAMobileDevice` bound to
`WHA RF Feature Setup` (guided setup step 50); `Application Area Setup` gained `WHA Mobile Device`
through this feature's own tableextension; the app-area subscriber sets it from `Enabled` with
`SkipOnMissingLicense`/`SkipOnMissingPermission` both `true`; the setup page is `ApplicationArea =
All` while the handheld, the device list and the card carry `WHAMobileDevice`. The API page guards
its write triggers with `CheckEnabled`.

## MCP configuration

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Mobile Device` | `mobileDevice` | `WHA API RF Device` | read, create, modify — **not delete** |
| `Warehouse Advanced - Demo Mobile Device` | `demoMobileDevice` | `WHA API Demo RF Device` | run `importDemoData` only |

Delete is withheld: a device row is the audit trail of which handheld was where and who had it.
**There is no agent tool for the flow itself** — an agent cannot sign in, take work, or confirm a
job. Work confirmed by something that was not standing in the aisle is exactly the falsification the
scan steps exist to prevent. Agent instructions:
[../agent-instructions/WarehouseAdvanced-MobileDevice.md](../agent-instructions/WarehouseAdvanced-MobileDevice.md)
and [../agent-instructions/WarehouseAdvanced-Demo-MobileDevice.md](../agent-instructions/WarehouseAdvanced-Demo-MobileDevice.md).

## Demo data

`WHA Demo RF Device` seeds three devices under fixed codes `DEMO-RF-001..003`: one tied to a
location, one that works anywhere, and one blocked. Each insert is guarded by
`if Rec.Get(...) then exit;`. `Import()` also builds the `WHA-RF` RapidStart package containing
`WHA RF Device` only.

## Tests

`WHA RF Tests` (codeunit 51003), 16 tests. The flow is a codeunit, so most of it is asserted
directly with unsaved task records and no database writes:

| Test | Asserts |
|---|---|
| `SignInRefusesAnUnknownDevice` / `SignInRefusesABlockedDevice` | Registration and blocking mean something |
| `SignInStampsTheDevice` | Who had it, when, and which location it brings back |
| `AnUnregisteredDeviceIsAllowedWhenRegistrationIsOff` | Trying the screen from a desktop needs no ceremony |
| `TheFirstStepIsTheBinToTakeFrom` / `AJobWithNoBinsGoesStraightToConfirm` | Steps follow what the job names |
| `ScanningCanBeSwitchedOffEntirely` | The one-tap mode |
| `ScanningTheWrongBinIsRefused` / `ScanningTheWrongUnitIsRefused` | The mistakes this exists to catch |
| `ScanningTheRightBinMovesOn` | The step order |
| `ScansAreNotCaseSensitiveOrSpaceSensitive` | Scanner reality |
| `TheHandlingUnitCanBeScannedByItsLabel` | Number or SSCC, same pallet |
| `TheInstructionNamesTheBin` | The instruction is the interface |
| `ConfirmingBeforeTheStepsAreDoneIsRefused` | Confirm cannot skip the scans |
| `ConfirmingFinishesTheJob` | The task completes and is stamped as started |
| `HandingBackReturnsStartedWorkToTheQueue` | The fix above, through the flow |
| `WorkIsOfferedOnlyAtTheDeviceLocation` | A handheld never sends an operator across the site |
| `DemoImportIsIdempotent` | The seeder is safe to re-run |

## Not done

- **Prototyped against operators.** The single most valuable thing missing, and the plan says so.
  Nothing below should be built until the step sequence has been watched in use.
- **Offline tolerance.** The plan's own description of this feature includes an "offline-tolerant
  confirm"; there is none. A handheld that loses connectivity loses its place, and the job stays
  assigned to the operator until they hand it back or pick it up again. Doing this properly means a
  queued confirmation on the device, which is a client-side problem this page set cannot solve
  alone.
- **The operator's place is session state, not stored.** Closing the page loses the current step,
  though not the job.
- **No quantity prompt, no short pick, no exception handling** — no way to say "there are only 4
  here, not 12". This is the first thing real operators will ask for, and it needs the directed work
  side to model a partial completion first.
- **No scan of the item or lot**, only the handling unit. Item-level jobs are confirmed without
  proving what was picked.
- **Getting-started in the customer language** — the language has not been confirmed.
