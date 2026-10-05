# warehouse-advanced-bc

AL app for Dynamics 365 Business Central Cloud delivering advanced warehouse management
features beyond the standard app.

Standard Business Central covers zones, bins, directed put-away and pick, and warehouse
documents. This app targets the layer above that — the capabilities customers normally
leave BC for and buy a dedicated WMS to get.

## Status

All fourteen candidate features ship a first working segment, on top of a foundation and three
shared engines. Every feature has its own setup, its own `Enabled` switch and application area, API
pages grouped per feature, an MCP configuration, sample data, and a test codeunit. The test app holds
**577 tests**, and both projects build with zero errors against Business Central 29 W1.

| Area | What ships |
|---|---|
| Foundation | Guided setup hub and per-feature wizard, feature facade, role centre with tiles contributed by the features, permission sets |
| Handling units | Licence plates and SSCCs, nesting, contents, move as one |
| Directed work | Task queue with priority and operator assignment, partial completion, work raised from warehouse receipts and shipments, optional write-back of quantities to the document |
| Handheld | Scanner-shaped page set and terminal add-in, device register, scan-through flows, short pick |
| Wave management | Waves by a swappable strategy, templates, workload capped in minutes of work |
| Replenishment | Min/max per pick bin, look-ahead against promised demand, pre-replenishment for a wave |
| Counting | Blind count sheets, tolerance, approval before a difference is accepted |
| Quality hold | Hold a handling unit and its contents, three dispositions, an audit trail that cannot be deleted |
| Packing | Packing bench: open, fill, verify and close a carton |
| Labelling | GS1 SSCC with check digit or sequential licence plate, label layouts |
| Labour management | Engineered standards, measured time, indirect time |
| Slotting | ABC velocity from pick history, re-slotting proposals |
| Dock and yard | Doors, yard positions, booked and checked-in vehicle visits |
| Analytics | Five operational measures kept as comparable snapshots |
| Integration | Message spine with handler dispatch for an external system, retention through Business Central's retention policies |
| Shared engines (not features) | Inventory posting, warehouse registration, telemetry |

What is still open:

- The app has **no customer**. [app/docs/modules.md](app/docs/modules.md) and
  [app/docs/gap-analysis.md](app/docs/gap-analysis.md) are the discovery agenda for the day one
  appears. Where a decision would need a customer fact, the app ships the least invasive default
  and makes the alternatives swappable.
- Whether the app keeps its own queue of work beside Business Central's warehouse activities or works
  on top of them is recorded in [app/docs/scope-fork.md](app/docs/scope-fork.md).
- The integration messages are built on assumed contracts, and the handheld has not yet been used by
  an operator.

[app/docs/implementation-plan.md](app/docs/implementation-plan.md) is the detailed delivery log, and
[app/docs/getting-started-english.md](app/docs/getting-started-english.md) is the end-user guide.

## Repository layout

```
warehouse-advanced-bc.code-workspace   Open THIS in VS Code, not the repo folder
.bc-conventions/        Shared BC conventions — gitignored, wired in locally (see below)
app/                    Main extension — an AL project root
  app.json              Manifest — object range 55000..58999, target Cloud
  AppSourceCop.json     Affix enforcement (WHA)
  wha.ruleset.json      Project ruleset; includes the shared one
  .vscode/              AL settings + launch.json.template (launch.json is local-only)
  docs/                 Feature documentation (FEAT-*/), planning docs, agent instructions
  layout/               Report layouts
  Translations/         .xlf translation files (.g.xlf is generated, not committed)
  src/
    Core/               Foundation, guided setup, role centre
    PermissionSet/      Permission set objects for the whole app
    Posting/            Shared inventory posting engine (not a feature)
    Registration/       Shared warehouse registration engine (not a feature)
    Telemetry/          Shared telemetry for unattended runs (not a feature)
    <Feature>/          One folder per feature, same subfolder shape
test/                   Test extension — an AL project root, object range 59000..59999
  src/codeunits/        One test codeunit per feature
tools/
  build.ps1             Compiles app and test with all four code analyzers
  test.ps1              Publishes both packages to the dev container and runs the tests
  rf-bench/             Playwright bench that runs the handheld add-in in a real browser
  rf-simulator/         Single-file browser stand-in for the handheld
  rdlc-check/           Checks the RDLC report layouts
```

### Why `.vscode` lives in `app/` and not at the repo root

The AL extension only activates for a folder that has `app.json` **at its root**. This repo
keeps `app/` and `test/` as two separate AL projects, so the repo root is not an AL project
and opening it directly gives you no AL commands at all — no symbol download, no F5.

`warehouse-advanced-bc.code-workspace` solves this by registering `app/` and `test/` as
workspace folders in their own right.

## Shared conventions — required to build

This project follows the owner's private BC conventions (greenfield scenario). Because they are
private and this repository is public, the conventions are **not committed** — `.bc-conventions/`
is gitignored and wired in locally as a directory junction:

```powershell
cmd /c mklink /J .bc-conventions <path-to-conventions>\bc-customer-project-template
```

**A fresh clone of this repo will not build without that step.** `app/.vscode/settings.json` points
`al.ruleSetPath` at `app/wha.ruleset.json`, which includes `../.bc-conventions/ruleset.json`, and
`test/.vscode/settings.json` points at the shared ruleset directly. Neither path resolves until the
conventions are junctioned. This is a deliberate trade to keep the methodology private while the
product repo stays public.

## Development environment

| | |
|---|---|
| Manifest target | `application` 28.1, runtime 17.0 (the minimum the app supports) |
| Build and test | Business Central **29.0.54011.55616 W1**, local artifact cache |
| Dev container | `bc29loc`, NavUserPassword auth, shared with the owner's other apps so they install side by side |
| Production | BC online, **W1** (no country localisation) |
| Distribution | **Per-tenant extension (PTE)** — not AppSource |
| Target | `Cloud` |

### Getting started

```powershell
git clone https://github.com/sta-ko-je-reko-ja-sam-reko/warehouse-advanced-bc.git
cd warehouse-advanced-bc

cmd /c mklink /J .bc-conventions <path-to-conventions>\bc-customer-project-template
copy app\.vscode\launch.json.template app\.vscode\launch.json   # edit for your container

git config user.name  "Your Name"          # config here is repo-local by design,
git config user.email "you@example.com"    # so a fresh clone starts with no identity
```

Build both projects and run the tests:

```powershell
.\tools\build.ps1                          # app + test, all four analyzers, BC 29 W1 symbols
.\tools\test.ps1 -ContainerName bc29loc    # elevated, BcContainerHelper; writes .output\TestResults.xml
```

Or open **`warehouse-advanced-bc.code-workspace`** in VS Code — not the repo folder — run
**AL: Download Symbols** against the `app` folder and press **F5**.

`app/.vscode/launch.json` is gitignored — it holds host-specific detail. Keep
`launch.json.template` in sync when the shape of the config changes.

## Conventions

Authoritative rules are in `.bc-conventions/`; [CLAUDE.md](CLAUDE.md) summarises them. The
essentials:

- One object per file, named `<ObjectName>.<ObjectType>.al` with the **affix stripped** —
  `table "WHA Handling Unit"` becomes `HandlingUnit.Table.al`
- `namespace WarehouseAdvanced.<Feature>;` on line 1 of every file
- Affix `WHA` on every object and every field added to a standard table
- Object names max 30 characters; permission set names max 20
- Polymorphic logic: no business logic in table triggers or subscriber bodies, and no custom event
  publishers — a dependent app extends the app through interface implementations
- Analysers CodeCop, UICop, AppSourceCop and PerTenantExtensionCop all run against the
  shared ruleset; the build is expected to stay zero-error

## License

Copyright (c) 2026 Marko Trnavac. All rights reserved — see [LICENSE](LICENSE). The source is
public to read; it is not open source.
