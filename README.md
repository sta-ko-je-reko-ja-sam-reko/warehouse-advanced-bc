# warehouse-advanced-bc

AL app for Dynamics 365 Business Central Cloud delivering advanced warehouse management
features beyond the standard app.

Standard Business Central covers zones, bins, directed put-away and pick, and warehouse
documents. This app targets the layer above that — the capabilities customers normally
leave BC for and buy a dedicated WMS to get.

## Status

Early scaffolding. No functional code yet. The module list in
[docs/modules.md](docs/modules.md) is a **candidate** scope that must be validated against
the customer's live WMS usage before implementation — see
[docs/gap-analysis.md](docs/gap-analysis.md).

## Repository layout

```
warehouse-advanced-bc.code-workspace   Open THIS in VS Code, not the repo folder
app/                    Main extension — an AL project root
  app.json              Manifest — object range 50000..50999, target Cloud
  AppSourceCop.json     Affix enforcement (WHA)
  .vscode/              AL settings + launch config (launch.json is local-only)
  src/<Module>/         Source, flat per functional module
  permissions/          Permission set objects
  translations/         .xlf translation files
test/                   Test extension — an AL project root
  app.json              Manifest — object range 51000..51999
  .vscode/              AL settings
docs/                   Module map and gap analysis
```

### Why `.vscode` lives in `app/` and not at the repo root

The AL extension only activates for a folder that has `app.json` **at its root**. This repo
keeps `app/` and `test/` as two separate AL projects, so the repo root is not an AL project
and opening it directly gives you no AL commands at all — no symbol download, no F5.

`warehouse-advanced-bc.code-workspace` solves this by registering `app/` and `test/` as
workspace folders in their own right, so AL activates for each while you still see the
whole repo in one window.

Object IDs are pre-allocated per module so parallel work cannot collide. The allocation
table is in [docs/modules.md](docs/modules.md).

## Development environment

| | |
|---|---|
| BC version | 28.1.49838.50988 (2026 release wave 1) |
| AL runtime | 17.0 |
| AL extension | ms-dynamics-smb.al 17.0 |
| Dev container | Docker, sandbox artifact, **US** localisation |
| Production | BC online, **W1** (no country localisation) |
| Distribution | **Per-tenant extension (PTE)** — not AppSource |
| Target | `Cloud` — production runs on BC online |

The dev container is US while production is W1. Warehouse objects overlap heavily so the
practical risk is low, but the container should be rebuilt from a W1 artifact before work
on modules that touch posting or documents.

`app.json` declares `"target": "Cloud"` so that cloud-unsafe constructs fail at compile
time on the local container rather than at deployment.

### Getting started

```powershell
git clone https://github.com/sta-ko-je-reko-ja-sam-reko/warehouse-advanced-bc.git
cd warehouse-advanced-bc
copy app\.vscode\launch.json.template app\.vscode\launch.json   # edit for your container
git config user.name  "Your Name"          # config here is repo-local by design,
git config user.email "you@example.com"    # so a fresh clone starts with no identity
```

Open **`warehouse-advanced-bc.code-workspace`** in VS Code — not the repo folder. Then run
**AL: Download Symbols** against the `app` folder and press **F5**.

`app/.vscode/launch.json` is gitignored — it holds host-specific detail. Keep
`launch.json.template` in sync when the shape of the config changes.

## Conventions

- One object per file, named `<ObjectName>.<ObjectType>.al`.
- Affix `WHA` on every object, field, and extension — enforced by AppSourceCop.
- Code analysers CodeCop, UICop, AppSourceCop, and PerTenantExtensionCop all run; the
  build is expected to stay analyser-clean.
- Cross-module calls go through a module's public codeunit, never directly to its tables.

## License

Not yet chosen. A public repository without a license file grants no rights to anyone —
add one before treating this as open source.
