# CLAUDE.md

Guidance for working in this repository.

## What this is

An AL extension for Dynamics 365 Business Central that adds warehouse capabilities BC does
not have in the standard app. It exists as part of a project replacing an existing **Qguar**
WMS integration for a customer, with further automation planned on top.

## Non-negotiable context

**`docs/modules.md` is a hypothesis, not confirmed scope.** The 15 modules listed there
describe what a tier-1 WMS typically has and BC typically lacks. They are *not* derived
from the customer's live Qguar installation. Do not build a module because it appears in
that table — `docs/gap-analysis.md` is the process for turning it into real scope. Building
to the full table is the single most likely way this project ends up several times larger
than it needs to be.

Do not name Qguar in public-facing repo content (README, package metadata, published docs).
It is another vendor's registered product; referring to it in internal docs is fine.

## Environment

| | |
|---|---|
| BC version | 28.1.49838.50988 (2026 wave 1) |
| AL runtime | 17.0 |
| Dev container | `http://mrt28/BC/?tenant=default`, docker, sandbox artifact, **US** |
| Dev endpoint | port 7049, **NavUserPassword** (`"authentication": "UserPassword"`) |
| Production | BC online, **W1** |
| Distribution | **Per-tenant extension (PTE)** — not AppSource |

The container is US while production is W1. Low risk for warehouse objects, but rebuild the
container from a W1 artifact before working on posting or documents.

### Determining a container's auth mode

Do not infer it from `GET /BC/dev/metadata` — that endpoint answers **anonymously** and
returns 200 regardless. Read the `WWW-Authenticate` header from an endpoint that genuinely
requires auth:

```powershell
$req = [System.Net.HttpWebRequest]::Create("http://mrt28:7048/BC/api/v2.0/companies")
try { $req.GetResponse() } catch { $_.Exception.Response.Headers['WWW-Authenticate'] }
```

`Basic realm=""` → NavUserPassword, so use `"authentication": "UserPassword"`.
`Negotiate` or `NTLM` → Windows, so use `"authentication": "Windows"`.

A mismatch surfaces as `Failed to establish SignalR hub connection ... 401 (Unauthorized)`
when starting a debug session.

Because distribution is PTE, the `50000..50999` range and the `WHA` affix need no
registration with Microsoft. The affix is kept regardless — it prevents collision with other
extensions installed in the customer's tenant.

## Opening the project

Open **`warehouse-advanced-bc.code-workspace`**, not the repo folder. The AL extension only
activates for a workspace folder with `app.json` at its root; `app/` and `test/` are separate
AL projects, so opening the repo root yields no AL commands at all.

Symbols can be copied from the local artifact cache instead of using AL: Download Symbols:

```powershell
$art = "c:\bcartifacts.cache\sandbox\28.1.49838.50988"
Copy-Item "$art\platform\ModernDev\PFiles\Microsoft Dynamics NAV\280\AL Development Environment\System.app" app\.alpackages\
Get-ChildItem "$art\us\Extensions" -Filter "*.app" |
  Where-Object { $_.Name -match "^Microsoft_(Application|Base Application|System Application|Business Foundation)_" } |
  Copy-Item -Destination app\.alpackages\
```

## Code conventions

- One object per file, named `<ObjectName>.<ObjectType>.al`
  (e.g. `WHAHandlingUnit.Table.al`, `WHAHandlingUnitMgt.Codeunit.al`)
- Affix **`WHA`** on every object, field, and extension — enforced by `app/AppSourceCop.json`
- Source is flat within each `app/src/<Module>/` folder, matching Base Application convention
- Object IDs are pre-allocated per module in `docs/modules.md`. Take IDs from your module's
  block only; the allocation exists so parallel work cannot collide.
- Cross-module calls go through a module's public codeunit, never directly to its tables
- Analysers CodeCop, UICop, AppSourceCop and PerTenantExtensionCop all run; keep the build
  analyser-clean

## Git workflow

`main` is protected and the rule applies to admins too. **Direct pushes are rejected** —
GH006. All changes go through a feature branch and a PR.

- 0 approving reviews required, so the repo owner can merge their own PR
- Linear history is required: merge with **squash or rebase**, never a merge commit
- Force pushes and branch deletion on `main` are blocked

Push restrictions on who may merge are an org-only GitHub feature; this is a personal repo,
so "only the owner merges" holds by account ownership rather than by rule.

## Git config is deliberately repo-local

Global git config on this machine is kept empty. Identity and the `gh` credential helper are
set in this repo's `.git/config` only. Consequences:

- A fresh clone has no identity — the first commit fails with `Author identity unknown`
  until `git config user.name` / `user.email` are set locally
- Never run `gh auth setup-git` without moving what it writes into the repo; it plants
  entries in global config
- The `credential.https://github.com.helper` key needs **two** entries — an empty one to
  reset inherited helpers, then the gh one — because system config sets
  `credential.helper = manager`

## Known outstanding items

- `publisher` is `"Default Publisher"` in both manifests and must be changed before real
  objects accumulate
- No LICENSE file; a public repo without one grants no rights to anyone
- Cutover model (big bang vs. parallel run with Qguar) is undecided
- The planned automation "on top of" the WMS has not been specified — whether it consumes
  the `Integration` module's API surface or drives the UI is unknown
