# RF terminal bench — a browser that actually runs the add-in

Until this existed, no browser had ever executed a line of
[`rfterminal.js`](../../app/src/MobileDevice/js/rfterminal.js). It compiled, its resources resolved,
and the document it is sent was covered by AL tests — but the script itself was unrun code shipping
to a warehouse floor. Publishing to Business Central needs a container credential this project does
not have, so the gap had no cheap route to closing.

This bench closes it without a container. It loads the **real, unmodified** add-in script and
stylesheet, stubs the one global they touch, feeds them **real state documents**, and asserts on
what they raise back.

Two modes, one harness page:

| | Command | For |
|---|---|---|
| **CI** | `npm test` | Headless Chromium, real key events, a wedge and screen matrix, 37 assertions. Runs on every push |
| **Device** | `npm run bench` | The same page on a real handheld over the LAN, with a real scanner in your hand |

## What it does not do

It does not emulate a make of handheld, and it must not start pretending to. Nobody here has held
one and measured it, and a profile named after a device nobody has used would be a specification
invented at a desk — the same debt `FEAT-INT-001` already carries and says so about. What the
profiles in [`bench/profiles.js`](bench/profiles.js) describe are **characteristics**: how fast the
characters arrive, what the wedge sends at the end, how big the screen is. Name a profile after a
device only once someone has measured that device.

It also settles nothing about whether the flow is right. That is
[operator-review.md](../../app/docs/FEAT-RF-001-MobileDevice/operator-review.md), it needs an
operator, and a green bench is not progress towards it.

## Running it

```bash
cd tools/rf-bench
npm install
npx playwright install chromium
npm test
```

`npm test` runs the fixture check first, then the suite. There is no Business Central, no company,
no symbols and no AL compile anywhere in it — which is why it can run in CI at all, while the AL
build cannot without private `bc-dev-templates` access.

## On a real handheld

```bash
npm run bench
```

It prints a LAN URL per interface. Open one on the device — same Wi-Fi, and the firewall has to
allow the port. You get the terminal at the device's real viewport, a state picker, and a log of
every event the add-in raised.

**Scan into it with the real scanner.** That is the whole point of this mode: it is the only way to
find out whether that device's wedge is configured to send keystrokes and an Enter, and whether the
on-screen keyboard stays down. Both are device settings, and both are invisible until a barcode goes
in. The **Send** button fakes a wedge for when you have no scanner to hand; it proves less.

## How the pieces fit

```
bench/index.html ─ loads ─► app/src/MobileDevice/css/rfterminal.css   (the real one)
                  ├ loads ─► bench/navstub.js         Microsoft.Dynamics.NAV, recording
                  ├ loads ─► app/src/MobileDevice/js/rfterminal.js     (the real one)
                  ├ loads ─► app/src/MobileDevice/js/rfterminalstart.js (the real one)
                  └ loads ─► bench/bench.js           fixtures in, events out, controls
```

`serve.mjs` serves the repository root, so the add-in files are loaded **from where they ship**.
Nothing is copied, so nothing can drift.

That is the difference between this and [`tools/rf-simulator/`](../rf-simulator/), which ports the
flow into 1200 lines of its own and can therefore only tell you about itself. The simulator answers
*"is this sequence sensible?"* at a desk. The bench answers *"does the shipping code work in a
browser?"*. Neither answers the other's question.

## The fixtures, and the drift that would make them worthless

[`fixtures/`](fixtures/) holds state documents in the shape
[`WHA RF Terminal State`](../../app/src/MobileDevice/codeunits/RFTerminalState.Codeunit.al) builds.
A bench fed a document that AL no longer produces tests nothing while looking green, so
`npm run check` reads the AL source, extracts every key it adds to the state, the device and the
job, and fails if any fixture disagrees.

**Be clear about the limit of that check.** It compares the *shape* — every key present, no key
invented. It cannot check the values, because it cannot run AL. A key renamed, added or removed in
the codeunit is caught. A value whose meaning changed underneath the same key is not.

**The values are hand-derived from the AL and have never been produced by a running Business
Central.** They match what the code reads as if it were run, which is not the same as what it does
when run. Replace them with captured output the first time this app is published to a container.

## Adding a state

1. Write the document to `fixtures/<name>.json`.
2. Add `<name>` to `FIXTURES` in [`bench/profiles.js`](bench/profiles.js).
3. `npm run check` to confirm the shape.

Every fixture is drawn by the `drawing` suite automatically, so a new one is covered the moment it
is listed.
