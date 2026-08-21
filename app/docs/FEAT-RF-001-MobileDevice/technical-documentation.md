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
**Segment 2** — the short pick: reporting from the aisle that there is less on the shelf than the
job asks for.

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
| `WHA RF Terminal` | controladdin | — | `app/src/MobileDevice/controladdins/RFTerminal.ControlAddIn.al` |
| `WHA RF Terminal State` | codeunit | 50104 | `app/src/MobileDevice/codeunits/RFTerminalState.Codeunit.al` |
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
| `StartShortPick` | Move to reporting that there is less on the shelf than the job asks for |
| `ShortPick` | Finish the job with what was actually found, and why |
| `HandBack` | Return the job to the queue |

`WHA RF Flow` is an **extensible enum implementing that interface**, with `WHA RF Standard Flow` as
its `DefaultImplementation`, and the setup names which value is in use. So a customer whose operators
work differently gets a new enum value and one codeunit — the screen, the device register, the
enablement and the queue underneath are all untouched. This is the same shape the app uses for
feature setup and for integration message types.

### The standard flow

```
SignIn ──► GetWork ──► [ScanFrom] ──► [ScanUnit] ──► [ScanTo] ──► Confirm ──► GetWork
                            └──────────── ShortPick ────────────────┘
```

**Short pick is reachable from any step while holding a job**, not only at the end — an operator
knows the shelf is short the moment they look at it, and making them scan their way to the end
first would be theatre. It asks for the quantity found and a reason, then closes the job through
`CompleteShort` in directed work.

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

## The terminal — a control add-in that decides nothing

The handheld page is a Business Central card page, which is a desktop shape: small type, small
targets, and a layout that assumes a mouse. `WHA RF Terminal` is a control add-in that draws the
same page as a scanner instead — one instruction in large type, one scan box that keeps the focus,
and three keys big enough for a gloved hand.

**It contains no logic, and that is the whole design.** The add-in is sent one state document by
`WHA RF Terminal State` and draws it. Every decision — which step, what the instruction says,
whether a scan is wanted, what a wrong scan is told, which key does what — is already made in AL by
`WHA IRFFlow` before the document is built. The script cannot reach a record, and the events it
raises (`Scanned`, `NextTaskRequested`, `ConfirmRequested`, `ShortPickRequested`,
`HandBackRequested`) are the same five things the page's own actions do.

The reason for the split is that **nothing in this project can run JavaScript**. There is no test
runner for it, no container to publish to, and no way to assert on what the script did. A terminal
whose behaviour lived in the script would be a second implementation nobody could check — which is
exactly what `tools/rf-simulator/` is, and it carries that debt openly. So the behaviour stays in
AL where the tests are, and the document it produces is what the tests assert on.

### What the terminal asks of the hardware

Nothing in this feature knows what make of device it is running on, and nothing should. `WHA RF
Device` records a code, a description, a location and a blocked flag — there is no model, vendor or
capability field, and no code path branches on one. The whole contract with the hardware is two
lines:

- **A current browser**, because the screen is the web client. A device whose only interface is a
  terminal session has no path to this screen at all; that is a hardware replacement, not a setting.
- **The scanner in keyboard-wedge mode with an Enter suffix**, because `submitScan` is reached from
  a `keydown` on Enter and nothing else. Every scanner has this setting under some name.

Both are met out of the box by current handhelds. Neither is worth a setup field: a device that
fails either one fails it for every flow, and the failure is fixed on the device.

**The scan box sets `inputmode="none"`.** The blur handler puts focus back in the box and keeps it
there, so on a touch device without the attribute the on-screen keyboard would open at sign-in and
never close, covering the instruction the operator is meant to read. Suppressing it costs the
ability to key a code by hand on a touch-only device — a physical keypad still works, since those
are hardware keys. **Classic fields** is the way back for that case, which is what it is for.

### The bench

Nothing in this project can run JavaScript — which was true of the *tests*, and was taken to mean the
script could not be checked at all. `tools/rf-bench/` is the correction. It is not part of the app
and ships in nothing: a static server rooted at the repository, a page that loads
`app/src/MobileDevice/js/rfterminal.js` **by its shipping path** so no copy can drift, a stub of the
one global the add-in calls, and Playwright driving it with real key events.

Two things it is deliberately not. It is **not a device emulator** — no profile is named after a
make of handheld, because nobody here has measured one and a profile invented at a desk is a
specification nobody can trust. And it is **not the operator review**, which still needs an operator.

The same page served over the LAN is how a real handheld gets used against it: real screen, real
scanner, real wedge configuration. That is the only way to find out whether the two hardware
requirements above are actually met on a given device.

### Simulator mode

The same add-in, with `simulator` set, draws a device frame around the screen and offers the labels
within reach as buttons: the bin the job names, its neighbour, the item, the handling unit and its
SSCC. It is a page action, not a setup field — a session-only choice, off by default, and it changes
nothing about how work is done.

Two properties of it are deliberate:

- **The wanted label is never first.** Whether an operator scans what they were asked for or the
  first barcode they see is the finding the operator review exists to get; offering the right answer
  first would answer the question for them.
- **No labels are sent at all unless simulator mode is on.** On a real handheld the labels are on the
  racking. A list of them on the screen would be a way of finishing a job without walking anywhere,
  and it would be in the app rather than in a tool somebody chose to open.

### What is still shown as ordinary fields

The short-pick form. The quantity found is a decimal and the reason is an enum, and both are worth
more as Business Central fields — validated, translated, and extensible by an `enumextension` —
than as script. While that form is open the terminal's main key is **dead on purpose**: confirming
before the fields are filled in would be refused by the flow, and an operator reads a refusal as the
device being broken.

**Classic fields** is the other half of that. The page's original groups are still there, hidden
behind an action, so an operator whose add-in does not load is not left with a blank screen.

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
| `ReportingShortAsksHowManyWereFound` | Short pick asks rather than assuming |
| `TheShortStepSaysHowManyWereAskedFor` | The operator can see what they are short against |
| `AWholePalletJobCannotBeReportedShort` | And is told what to do instead |
| `ConfirmingShortFinishesTheJobWithWhatWasFound` | Four of twelve, from the aisle |
| `WorkIsOfferedOnlyAtTheDeviceLocation` | A handheld never sends an operator across the site |
| `DemoImportIsIdempotent` | The seeder is safe to re-run |

## Not done

- **Prototyped against operators.** The single most valuable thing missing, and the plan says so.
  Nothing below should be built until the step sequence has been watched in use.
  [operator-review.md](operator-review.md) is the script for that session: what to set up, what to
  watch, and which finding changes which object. It is written to be run by someone who did not
  build this.

  **The infrastructure excuse is gone.** `tools/rf-simulator/index.html` runs the same step
  sequence and the same wording in a browser, with no company, no sample data and no container —
  so the sequence-and-wording half of the review can be run this afternoon. It does not replace the
  floor session, and the file says so itself. What remains missing is an operator, not a
  prerequisite. **If the flow below changes, that file is wrong until somebody changes it too.**
- **Offline tolerance.** The plan's own description of this feature includes an "offline-tolerant
  confirm"; there is none. A handheld that loses connectivity loses its place, and the job stays
  assigned to the operator until they hand it back or pick it up again. Doing this properly means a
  queued confirmation on the device, which is a client-side problem this page set cannot solve
  alone.
- **The operator's place is session state, not stored.** Closing the page loses the current step,
  though not the job.
- **The add-in has run in a browser, but never in Business Central.** `tools/rf-bench/` loads the
  real script and stylesheet from where they ship, feeds them state documents in the shape
  `WHA RF Terminal State` builds, and asserts on what they raise — so focus handling, the wedge's
  Enter, the suppressed on-screen keyboard, the disabled keys and the four screen sizes are now
  covered rather than assumed. See [the bench's README](../../../tools/rf-bench/README.md).

  What that does **not** cover: the add-in has still never been published, so nothing has exercised
  the real `Microsoft.Dynamics.NAV` bridge, the real state documents produced by a running AL
  codeunit, the Business Central page hosting it, or a real scanner. The bench's fixture values are
  hand-derived from the AL. Replace them with captured output the first time this is published to a
  container.
- **No other exception handling.** The short pick is in (segment 2), but there is still no way to
  report a wrong item in the bin, a damaged pallet that should be quarantined, or a bin that is not
  where the job says it is. Each is a different conversation with directed work, and each should
  come out of the operator review rather than out of a developer's imagination.
- **No scan of the item or lot**, only the handling unit. Item-level jobs are confirmed without
  proving what was picked.
- **Getting-started in the customer language** — the language has not been confirmed.
