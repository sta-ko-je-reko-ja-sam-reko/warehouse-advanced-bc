# Handheld bench — a browser stand-in for `FEAT-RF-001`

`index.html` is the warehouse handheld running with no Business Central behind it. Open the file in
a browser; there is nothing to install, no server, and no network call. It is one self-contained
file so it can be mailed, hosted anywhere, or opened from a phone.

## Mostly superseded

The app now has a **control add-in** that draws the same terminal inside Business Central, with a
**Simulator** action that puts a device frame around it and offers the labels as buttons. That runs
the real `WHA IRFFlow`, so it cannot drift from what the app does — which is the one problem this
file has by construction.

Use the bench only for what it still does better: it needs **no Business Central at all**. Hand it to
somebody with no login, or open it on a phone with nothing installed. For anything else, use
**Handheld → Simulator** in a test company.

## Why it exists

[`operator-review.md`](../../app/docs/FEAT-RF-001-MobileDevice/operator-review.md) is the highest
priority piece of work on this feature, and it has never been run. Its prerequisites are a test
company, sample data, an enabled feature and a container credential this project does not have — so
the review has stayed blocked on infrastructure rather than on anyone's time.

The bench removes that block for the part of the review that is about the *screen*: the step
sequence, the wording, the number of scans a job costs, and what an operator does when the bin is
empty.

## What is faithful, and what is not

Ported line for line from `app/src/MobileDevice/codeunits/RFStandardFlow.Codeunit.al`:

- the seven steps and the branching between them (`FirstStep`, `AfterFromBin`, `AfterUnit`)
- every instruction and every refusal, **verbatim from the AL labels**
- scan matching, including `Normalise` and the handling unit's SSCC as an alternative to its number
- the three `WHA RF Setup` toggles that change the flow, and the sign-in rules for an unregistered
  or blocked handheld

Not faithful, and deliberately so:

- **No database.** Tasks live in an array, and a task's state resets when the page reloads.
- **No task assignment or locking.** One operator, one device, no contention.
- **No posting, no handling units, no waves.** Completing a job changes a colour and nothing else.

## What it cannot test

A desk review with tapped labels does not test what an operator does with a scanner in one hand and
a pallet in the other. `operator-review.md` asks for real bins with printed barcodes and a device
with the real form factor, and it is right to. **Use the bench for sequence and wording; run the
real session on the floor.**

## Keeping it honest

If `WHA RF Standard Flow` changes, this file is wrong until somebody changes it too. It is not
compiled, not tested, and not shipped inside the extension — `tools/` is outside the AL project, so
nothing here reaches a tenant. Treat a divergence as a bug in the bench, never as a second opinion
about how the flow should work.

## The session log

Every scan, refusal, tap and job is timestamped. **Copy the log** puts the log, the counters and the
note-taker's free text on the clipboard in one block, ready to paste into the findings table in
`operator-review.md`. The counters worth watching are *wrong scans* and *seconds per job* — they are
the two numbers that argue for or against `Confirm by scan`.
