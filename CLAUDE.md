# CLAUDE.md

Guidance for working in this repository.

## Authoritative rules live elsewhere — read them first

**This project MUST follow the owner's private BC conventions repository.** They are
wired in at `.bc-conventions/` (gitignored — see "Shared conventions" below) and they
**override anything in this file** if the two ever disagree.

Scenario: **greenfield** (`bc-greenfield-template`) — a brand-new app with no NAV ancestor.
The incumbent is a third-party WMS, not a Navision solution, so the NAV→BC migration
machinery does not apply. Shared AL guides and the ruleset come from
`bc-customer-project-template`.

Before authoring any object, read:

| Need | File |
|---|---|
| Coding standards (naming, namespaces, cops, labels) | `.bc-conventions/instructions/02-al-coding-standards.md` |
| Folder + file naming | `.bc-conventions/instructions/03-source-folder-layout.md` |
| Per-object-type authoring guide | `.bc-conventions/al-object-types/<type>.md` |
| Feature setup + `Enabled` toggle | `.bc-conventions/al-object-types/_patterns/feature-setup-and-toggle.md` |
| Assisted setup hub + wizard | `.bc-conventions/al-object-types/_patterns/assisted-setup-orchestration.md` |
| Polymorphic table logic (**mandatory**) | `.bc-conventions/al-object-types/_patterns/polymorphic-table-logic.md` |
| Greenfield feature workflow | `bc-greenfield-template/instructions/02-feature-workflow.md` |

## What this is

An AL extension for Dynamics 365 Business Central adding warehouse capabilities BC does not
have in the standard app. It reimplements the functional footprint of a **third-party WMS** in
Business Central. It began as a project to replace that WMS integration for a customer; since
2026-08-20 it has **no specific customer** and is built as a product (see the top of
`app/docs/implementation-plan.md`). All fourteen candidate features ship a first segment.

## Non-negotiable context

**`app/docs/modules.md` is a hypothesis, not confirmed scope.** The modules describe what
a tier-1 WMS typically has and BC typically lacks; they are *not* derived from a live WMS
installation, because there is no customer site to derive them from. Where a decision would need
a customer fact, pick the **least invasive default and make the alternatives swappable** (an
extensible enum whose values each bind their own implementation). `app/docs/gap-analysis.md`
stays as the interview agenda for the day a customer appears.

Do not name the incumbent WMS or its vendor in repo content — it is another vendor's
registered product. Call it "the incumbent WMS" or "the system being replaced".

## Shared conventions (`.bc-conventions/`)

The conventions repository is **private**; this repo is **public**. The conventions are therefore
**not committed** — `.bc-conventions/` is gitignored and wired in locally as a directory
junction:

```powershell
cmd /c mklink /J .bc-conventions <conventions>\bc-customer-project-template
```

A junction rather than a copy, so the rules track the conventions repository instead of drifting.

**Consequence, by deliberate choice:** a fresh clone of this public repo **will not build** —
`app/wha.ruleset.json` includes `../.bc-conventions/ruleset.json` (and `test/.vscode/settings.json`
points `al.ruleSetPath` straight at it), and that path will not resolve until the private repo is
cloned and junctioned. Anyone building this (including CI) needs access to the conventions repository.

Note the ruleset is configured through the **`al.ruleSetPath` setting**, not through an
`app.json` property. `"ruleset"` is not valid in `app.json` on AL runtime 17 — the compiler
rejects it with `AL0124`. The conventions' bootstrap instruction was wrong on this point.

`app/` points `al.ruleSetPath` at its own `app/wha.ruleset.json`, which includes the shared ruleset and
hides only AS0081/PTE0012 — the warnings `internalsVisibleTo` raises. `app/app.json` makes internals
visible to the test app alone, so tests can reach `internal` procedures (guided setup, posting checks).
`test/` still points at the shared ruleset directly.

## Environment

| | |
|---|---|
| Manifest target | `application` 28.1, runtime 17.0 — the minimum the app supports |
| Build and test | BC **29.0.54011.55616 W1**, artifact `c:\bcartifacts.cache\sandbox\29.0.54011.55616` |
| Dev container | `bc29loc` (`http://bc29loc/BC/?tenant=default`), shared with the owner's other apps so they install side by side |
| Dev endpoint | port 7049, **NavUserPassword** (`"authentication": "UserPassword"`) |
| Production | BC online, **W1** |
| Distribution | **Per-tenant extension (PTE)** — not AppSource |
| Publisher | `matr` |
| Affix | `WHA` |
| Object IDs | app `55000..58999`, test `59000..59999` — this app's block in the PTE range shared by all the owner's apps, which must install side by side; never use IDs outside it (the registry lives in the conventions repository) |

The container and the build artifact are W1, the same as production.

Note the shared `ruleset.json` was authored for **OnPrem** partner extensions (it hides
AS0013/AS0053/AS0084 on that basis). This app targets **Cloud** as a PTE. The suppressions
remain harmless, but revisit them if the app ever moves toward AppSource.

### Determining a container's auth mode

Do not infer it from `GET /BC/dev/metadata` — that endpoint answers **anonymously** and
returns 200 regardless. Read `WWW-Authenticate` from an endpoint that requires auth:

```powershell
$req = [System.Net.HttpWebRequest]::Create("http://bc29loc:7048/BC/api/v2.0/companies")
try { $req.GetResponse() } catch { $_.Exception.Response.Headers['WWW-Authenticate'] }
```

`Basic realm` means NavUserPassword; `Negotiate` or `NTLM` means Windows. A mismatch surfaces
as `Failed to establish SignalR hub connection ... 401 (Unauthorized)`.

## Building and running the tests

`tools/build.ps1` compiles `app/` and then `test/` with all four code analyzers, against the BC 29 W1
artifact in the local cache (refreshing `.alpackages` from it), using the AL extension's `alc.dll` and
the .NET 10 runtime VS Code installed. The bar is zero errors and zero warnings for both projects.
`tools/test.ps1` (elevated, BcContainerHelper) publishes both packages to the shared `bc29loc`
container through the dev endpoint, runs every test codeunit of the test app and writes
`.output/TestResults.xml`:

```powershell
.\tools\build.ps1
.\tools\test.ps1 -ContainerName bc29loc
```

The test runner rolls back after each **test codeunit**, not after each test, so tests inside one
codeunit see each other's data. New tests use keys and dates of their own and put back any setup they
change.

## Opening the project

Open **`warehouse-advanced-bc.code-workspace`**, not the repo folder. The AL extension only
activates for a workspace folder with `app.json` at its root; `app/` and `test/` are separate
AL projects, so opening the repo root yields no AL commands at all.

Symbols do not need AL: Download Symbols: `tools\build.ps1` refreshes `app\.alpackages` and
`test\.alpackages` from the BC 29 W1 artifact in the local cache on every build.

## Code conventions (summary — the authority is `.bc-conventions/`)

- **Source layout:** `app/src/Core/`, `app/src/PermissionSet/`, `app/src/<Feature>/`, each
  feature with `tables/ pages/ codeunits/ enums/ interfaces/ tableextensions/` subfolders.
- **File name = object name with the affix STRIPPED**, spaces and `-`/`.` removed, then
  `.<ObjectType>.al`. `table "WHA Handling Unit"` becomes `HandlingUnit.Table.al`. Use the
  *abbreviated* object name if you abbreviated it — mismatching trips AA0215/LC0015.
- **Namespace on line 1 of every file:** `namespace WarehouseAdvanced.<Feature>;` then
  `using` for every other namespace referenced, **sorted alphabetically** (AA0477). Adding a
  namespace kills global lookup — Microsoft objects then need a `using` too.
- **Affix `WHA`** on every object and every field added to a standard table.
- **Object names max 30 chars; `permissionset` names max 20 chars** (compiler error beyond).
  Descriptive wording goes in the `Caption`.
- **Polymorphic table logic is mandatory.** No business logic in a table trigger, a
  `tableextension` trigger, or a subscriber body — each delegates one line to a swappable
  interface implementation.
- **No custom event publishers in this app.** Do not add `[IntegrationEvent]` or
  `[BusinessEvent]`. Extension happens through **interface implementations**, not events: an
  extensible `enum … implements "<Interface>"` with a `DefaultImplementation`, where each value
  binds its own implementation. A dependent app extends the app by adding an `enumextension`
  value with its own implementation — never by subscribing to our event.
  The single exception the polymorphic pattern allows is an `OnResolve…` publisher whose only
  purpose is to let a dependent app **substitute a default interface implementation** where no
  setup field or reliable early call site exists. Nothing else justifies a publisher.
  (Subscribing to *Microsoft's* publishers is unaffected — that is how we react to base app
  events, and those subscriber bodies still delegate one line to an interface.)
- **Every field:** `Caption` + `ToolTip` (author the ToolTip on the **table field**, not the
  page field). Every table: `DataClassification`, PK key named `PK`, `Clustered = true`.
- **Every page:** `ApplicationArea`, explicit `UsageCategory`. Enablement UI (setup page,
  wizard) is `ApplicationArea = All`; operational UI takes the feature's dedicated area.
- **Codeunits:** default cross-object procedures to `internal`; `///` docs on public and
  internal ones. **No inline comments anywhere in AL.** `SetLoadFields` before every
  `Get`/`Find*`.
- **Labels** for all user-visible strings, suffixed `Msg`/`Err`/`Qst`/`Txt`/`Lbl`/`Tok`, with
  a `Comment` naming every placeholder.
- **Errors as errors:** AA0008, AA0073, AA0137, AA0139, AA0217, AA0233, AL0606. Zero-error
  builds. Disable a rule in the ruleset with a `justification` — never disable an analyzer.
- **Every new object goes into a permission set as it is created.**
- **Test codeunits follow the same file-naming rule as everything else** — object name, affix
  stripped, spaces removed, then `.Codeunit.al`. `codeunit "WHA Handling Unit Tests"` becomes
  `HandlingUnitTests.Codeunit.al`. **Not** `<Feature>.Test.Codeunit.al`: that form is what
  `.bc-conventions/instructions/03-source-folder-layout.md` §4 says, but AA0215 rejects it, so put
  "Tests" in the **object name** instead. The `test/` project needs its own `AppSourceCop.json`
  carrying `mandatoryAffixes`, or AA0215 cannot tell `WHA` is an affix and demands the affix-kept
  file name.
- **Run the analysers against `test/` too**, not just `app/`. A test-project compile without
  `/analyzer` flags reports nothing and proves nothing.

## Git workflow

`main` is protected and the rule applies to admins too. **Direct pushes are rejected** —
GH006. All changes go through a feature branch and a PR.

- 0 approving reviews required, so the repo owner can merge their own PR
- Linear history required: merge with **squash or rebase**, never a merge commit
- Force pushes and branch deletion on `main` are blocked

Push restrictions on who may merge are an org-only GitHub feature; this is a personal repo,
so "only the owner merges" holds by account ownership rather than by rule.

## Git config is deliberately repo-local

Global git config on this machine is kept empty. Identity and the `gh` credential helper are
set in this repo's `.git/config` only. Consequences:

- A fresh clone has no identity — the first commit fails with `Author identity unknown`
- Never run `gh auth setup-git` without moving what it writes into the repo
- `credential.https://github.com.helper` needs **two** entries — an empty one to reset
  inherited helpers, then the gh one — because system config sets `credential.helper = manager`

## Known outstanding items

- **Customer-language getting-started files are deliberately deferred.** `feature-ready.md` requires
  `getting-started-<lang>.md` per feature, and no feature has one. This is an accepted deviation
  until a customer is engaged and the language is known — not an oversight. English getting-started
  files are written as features ship, so the translation pass has something to work from.

- Manifest URLs point at **dmom.ai** (`/privacy`, `/eula`, `/help`). **None of those pages
  exist yet** — there is no site on the domain. AppSourceCop only validates URL shape, so the
  build passes, but the links are dead until the pages are published. **Decided: leave the
  manifest pointing there and carry the debt**, rather than repoint it at the repository.
  The consequence is that a customer following either link gets nothing, and that must be
  closed before delivery, not before the next feature.
- **Licence: proprietary, all rights reserved.** `LICENSE` at the repo root is the notice to
  anyone who can read the public source and grants nothing. `app/docs/eula.md` is the
  customer-facing agreement and is **draft, unreviewed, and has two clauses deliberately
  left unfilled** — governing law and support terms, both commercial decisions.
- `app/docs/privacy-statement.md` is the draft content for the privacy page
- `app/img/AppLogo.png` is a generated placeholder, not real branding
- **CI covers the handheld's script only.** `.github/workflows/rf-bench.yml` runs
  `tools/rf-bench/` — Playwright against the real control add-in — because it needs no AL compile
  and therefore no access to the private conventions repository. **There is still no CI for the AL build**, and
  there cannot be until the conventions repo is reachable from a runner.
- **No interface specification exists for the system being replaced, and none can be produced.**
  Confirmed with the customer. `FEAT-INT-001` was therefore built on assumed contracts — see the
  boxed note at the top of `app/docs/FEAT-INT-001-Integration/technical-documentation.md`. Treat
  every payload shape in that feature as provisional, and keep new guesses inside the handler
  codeunits where they are cheap to replace. Do not add a message type by touching existing objects.
- Cutover model (big bang vs. parallel run with the incumbent) undecided
- The planned automation "on top of" the WMS is unspecified
