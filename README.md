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
app/                    Main extension
  app.json              Manifest — object range 50000..50999, target Cloud
  AppSourceCop.json     Affix enforcement (WHA)
  src/<Module>/         Source, flat per functional module
  permissions/          Permission set objects
  translations/         .xlf translation files
test/                   Test extension, object range 51000..51999
docs/                   Module map and gap analysis
.vscode/                Shared editor settings; launch.json is local-only
```

Object IDs are pre-allocated per module so parallel work cannot collide. The allocation
table is in [docs/modules.md](docs/modules.md).

## Development environment

| | |
|---|---|
| BC version | 28.1.49838.50988 (2026 release wave 1) |
| AL runtime | 17.0 |
| AL extension | ms-dynamics-smb.al 17.0 |
| Dev container | Docker, sandbox artifact, **US** localisation |
| Target | `Cloud` — production runs on BC online |

`app.json` declares `"target": "Cloud"` so that cloud-unsafe constructs fail at compile
time on the local container rather than at deployment.

### Getting started

```powershell
git clone https://github.com/sta-ko-je-reko-ja-sam-reko/warehouse-advanced-bc.git
cd warehouse-advanced-bc
copy .vscode\launch.json.template .vscode\launch.json   # then edit for your container
```

Open the folder in VS Code, run **AL: Download Symbols**, then **F5**.

`.vscode/launch.json` is gitignored — it holds host-specific detail. Keep the template in
sync when the shape of the config changes.

## Conventions

- One object per file, named `<ObjectName>.<ObjectType>.al`.
- Affix `WHA` on every object, field, and extension — enforced by AppSourceCop.
- Code analysers CodeCop, UICop, AppSourceCop, and PerTenantExtensionCop all run; the
  build is expected to stay analyser-clean.
- Cross-module calls go through a module's public codeunit, never directly to its tables.

## License

Not yet chosen. A public repository without a license file grants no rights to anyone —
add one before treating this as open source.
