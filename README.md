# warehouse-advanced-bc

AL app for Dynamics 365 Business Central Cloud delivering advanced warehouse management
features beyond the standard app.

Standard Business Central covers zones, bins, directed put-away and pick, and warehouse
documents. This app targets the layer above that — the capabilities customers normally
leave BC for and buy a dedicated WMS to get.

## Status

Early scaffolding. No functional AL code yet. The module list in
[app/docs/modules.md](app/docs/modules.md) is a **candidate** scope that must be validated
against the customer's live WMS usage before implementation — see
[app/docs/gap-analysis.md](app/docs/gap-analysis.md).

## Repository layout

```
warehouse-advanced-bc.code-workspace   Open THIS in VS Code, not the repo folder
.bc-conventions/        Shared BC conventions — gitignored, wired in locally (see below)
app/                    Main extension — an AL project root
  app.json              Manifest — object range 50000..50999, target Cloud
  AppSourceCop.json     Affix enforcement (WHA)
  .vscode/              AL settings + launch config (launch.json is local-only)
  img/AppLogo.png       App logo (placeholder)
  Translations/         .xlf translation files (.g.xlf is generated, not committed)
  docs/                 Feature documentation + planning docs
  src/
    Core/               Foundation + assisted setup
      tables/ pages/ codeunits/ enums/ interfaces/ tableextensions/
    PermissionSet/      Permission set objects
    <Feature>/          One folder per shipped feature, same subfolder shape
test/                   Test extension — an AL project root
  app.json              Manifest — object range 51000..51999
  src/codeunits/        Test codeunits
```

Feature folders under `src/` are created **when a feature is actually scoped**, not up
front. Object IDs are pre-allocated per module in [app/docs/modules.md](app/docs/modules.md).

### Why `.vscode` lives in `app/` and not at the repo root

The AL extension only activates for a folder that has `app.json` **at its root**. This repo
keeps `app/` and `test/` as two separate AL projects, so the repo root is not an AL project
and opening it directly gives you no AL commands at all — no symbol download, no F5.

`warehouse-advanced-bc.code-workspace` solves this by registering `app/` and `test/` as
workspace folders in their own right.

## Shared conventions — required to build

This project follows the conventions in the private **`bc-dev-templates`** repo (greenfield
scenario). Because that repo is private and this one is public, the conventions are **not
committed** — `.bc-conventions/` is gitignored and wired in locally as a directory junction:

```powershell
cmd /c mklink /J .bc-conventions C:\Users\P16v\Documents\bc-dev-templates\bc-customer-project-template
```

**A fresh clone of this repo will not build without that step.** `app.json` sets
`"ruleset": "../.bc-conventions/ruleset.json"`, and the path will not resolve until the
private repo is cloned and junctioned. This is a deliberate trade to keep the methodology
private while the product repo stays public.

## Development environment

| | |
|---|---|
| BC version | 28.1.49838.50988 (2026 release wave 1) |
| AL runtime | 17.0 |
| AL extension | ms-dynamics-smb.al 17.0 |
| Dev container | Docker, sandbox artifact, **US** localisation, NavUserPassword auth |
| Production | BC online, **W1** (no country localisation) |
| Distribution | **Per-tenant extension (PTE)** — not AppSource |
| Target | `Cloud` — production runs on BC online |

The dev container is US while production is W1. Warehouse objects overlap heavily so the
practical risk is low, but the container should be rebuilt from a W1 artifact before work
on modules that touch posting or documents.

### Getting started

```powershell
git clone https://github.com/sta-ko-je-reko-ja-sam-reko/warehouse-advanced-bc.git
cd warehouse-advanced-bc

cmd /c mklink /J .bc-conventions C:\path\to\bc-dev-templates\bc-customer-project-template
copy app\.vscode\launch.json.template app\.vscode\launch.json   # edit for your container

git config user.name  "Your Name"          # config here is repo-local by design,
git config user.email "you@example.com"    # so a fresh clone starts with no identity
```

Open **`warehouse-advanced-bc.code-workspace`** in VS Code — not the repo folder. Then run
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
- Analysers CodeCop, UICop, AppSourceCop and PerTenantExtensionCop all run against the
  shared ruleset; the build is expected to stay zero-error

## License

Not yet chosen. A public repository without a license file grants no rights to anyone —
add one before treating this as open source.
