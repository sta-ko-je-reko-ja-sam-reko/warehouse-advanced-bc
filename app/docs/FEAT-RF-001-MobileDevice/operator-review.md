# FEAT-RF-001 - Operator Review

A script for putting the handheld in front of real operators, and for recording what they say in a
form that can change the code.

This is not a user guide — that is
[getting-started-english.md](getting-started-english.md). This is the session you run **before**
anything else is built on top of the handheld.

## Why this exists

The implementation plan calls `FEAT-RF-001` the feature with a disproportionate risk: *"a scanner UI
is a different interaction model, not a page set, and it is the feature most likely to be judged by
operators against what the incumbent already does."*

Everything in the current build is a guess about how people work: how many scans are worth the
proof they give, whether a short pick needs a reason, whether an operator ever wants to choose their
next job rather than be given one. **Those are not questions a developer can answer, and they are
cheap to change now and expensive to change later.** The step sequence sits behind a single
swappable interface (`WHA IRFFlow`) precisely so this review can rewrite it.

## Two ways to run it

**On the floor, with the real app.** What this document was written for, and what actually settles
the questions. Everything under *Before the session* applies.

**At a desk, with the real screen.** Open **Handheld** in a test company and choose **Simulator**.
The terminal draws itself as a device and offers the labels within reach as buttons, and everything
behind it is the real flow: a job finished there is finished. This is the better desk option now
that it exists, because nothing about it can drift from what the app does.

**At a desk, with the bench.** `tools/rf-simulator/index.html` is the same screen, the same step
sequence and the same wording, running in a browser with nothing behind it. It needs no company at
all, which is the one thing it still does better — hand it to somebody who has no Business Central
login. Everything else about it is now a second implementation of a thing the app can do itself. It needs no company, no
sample data, no container and no credential — which is why it exists: this review has been blocked
on infrastructure rather than on anybody's time since the feature shipped.

The bench settles **sequence and wording**: how many scans a job costs, whether the short-pick form
asks for the number an operator expects, what they do at an empty bin, and whether `Confirm by scan`
earns its keep. It settles **nothing** about a scanner in one hand and a pallet in the other. A
finding from the bench is a hypothesis; a finding on the floor is a decision.

Run the bench first anyway. It is free, and every wording problem it catches is one that does not
waste a floor session.

## Before the session

*(For the floor session. The bench needs none of it.)*

- [ ] A test company with **directed work** and **handheld** enabled, and sample data loaded.
- [ ] Real-looking work: at least 10 tasks, of at least three types, at the location you will use.
      Do not use one perfect task — the interesting behaviour is the fifth job in a row.
- [ ] The **real bins** you will visit, with **printed barcodes** on them. A review done at a desk
      with typed codes tests nothing that matters.
- [ ] At least one handling unit with a **printed SSCC label**.
- [ ] A device with the actual form factor operators use. A laptop browser is not a handheld.
- [ ] That device's **scanner set to keyboard-wedge mode with an Enter suffix**, checked in any
      text box before the session starts. Without it every scan is silent and you will spend the
      session debugging the device instead of watching the operator.
- [ ] A look at whether the **on-screen keyboard stays down** on that device. It should — the scan
      box asks for no keyboard — but no browser has ever run this screen, so confirm it rather
      than assume it.
- [ ] One task deliberately set up to be **short** — ask for 12 where there are 4.
- [ ] One task pointing at a bin that is **empty**.
- [ ] Somebody to take notes who is **not** the person running the session.

## Running it — 45 minutes, two or three operators, one at a time

Say this first, and mean it: *"This is a first version and we expect it to be wrong. You are not
being tested — it is. Say what you would say to a colleague."*

Then hand over the device and stop talking. **Do not explain the screen.** Every explanation you
give is a finding you have destroyed.

### 1. Cold start (5 min)

Give them the device on the sign-in step and say nothing.

- Do they scan the device label without being told?
- Do they know what to do after signing in?

### 2. Three jobs in a row (15 min)

Let them work three jobs without help.

- Where do they hesitate? Note **where their eyes go first** on each new screen.
- Do they read the instruction line, or do they look at the job details?
- Do they scan what they were asked to scan, or the first barcode they see?
- Count how many times they look at the screen per job. Fewer is better.

### 3. The short pick (10 min)

Give them the job asking for 12 where there are 4, with no warning.

- Do they find **Report short** without help? How long does it take?
- Is "quantity found" the number they expect to type, or do they try to type what is missing?
- Do the reasons match what they would actually say? **Write down the words they use**, and use
  those words as the reason captions.
- Ask: *"What would you do about the other eight?"* Their answer decides whether the follow-up task
  should be raised, and whether it should be a draft or go straight to the floor.

### 4. The empty bin (5 min)

Give them the job pointing at an empty bin.

- Do they report short with zero, or hand back, or something else?
- Ask which one they think is right. There is a real difference: a short pick with zero closes the
  job and tells the office; a hand back sends the next person to the same empty bin.

### 5. Interruption (5 min)

While they hold a job, tell them their supervisor needs them elsewhere.

- Do they hand back, or walk away with the job?
- Ask what they expect to happen to the job either way.

### 6. Questions afterwards (5 min)

- *"What did this stop you doing that you can do today?"*
- *"What did it make you do twice?"*
- *"Which scan felt pointless?"* — and the mirror: *"Which one would you keep even if it were
  optional?"*
- *"If you could change one thing about this screen, what?"*

## What to write down

For each finding, record: **what happened**, **what they expected**, and **which of the below it
changes**. A finding that changes nothing on this list is still worth keeping, but it is not what
this session is for.

| If they say | It changes |
|---|---|
| A scan is pointless, or they want another one | The step sequence — a new `WHA IRFFlow` implementation |
| The instruction did not tell them what to do | The `Instruction` labels in the flow |
| They looked at the job details, not the instruction | The page layout: what is at the top |
| The short reasons do not match how they talk | The `WHA Whse. Short Reason` enum captions and values |
| They expect the missing quantity to be re-picked | `Follow Up Short Picks` default, and whether the follow-up is a draft |
| They want to choose their job, not be given it | The queue design in `FEAT-TASK-001` — the biggest possible finding |
| They expect to scan the item as well as the pallet | A new step, and item-level confirmation in directed work |
| They want to work offline | The offline-tolerant confirm, which is not a page change at all |

## What counts as a result

Not "they liked it". The session has worked if you leave with:

1. **A decision on the step order** — keep, or a specific different one.
2. **The operators' own words** for the short reasons.
3. **An answer on the outstanding quantity** — report it, re-queue it as a draft, or re-queue it
   live.
4. **A list of what they do today that this cannot do at all.** This is the most valuable output
   and the one most likely to be missed, because it never comes up while working a job that the
   screen already supports.

Anything on that list that is not already in the *Not done* section of
[technical-documentation.md](technical-documentation.md) is genuinely new scope, and belongs in the
capability register that `gap-analysis.md` describes — not in a quick fix to the flow.

## After the session

- Write the findings into the register, not into someone's notebook.
- If the step order changes: **write a new `WHA IRFFlow` implementation and a new `WHA RF Flow` enum
  value.** Do not edit the standard flow into a shape nobody chose deliberately. Keeping both makes
  the second review a comparison rather than another cold start.
- Re-run this script after the change, with different operators.
