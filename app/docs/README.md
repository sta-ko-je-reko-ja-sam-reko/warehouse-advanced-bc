# Warehouse Advanced — Feature Documentation

Documentation for every feature in this app. The convention is governed by the shared
greenfield documentation standard (`.bc-conventions` + `bc-greenfield-template/instructions/05-documentation-standard.md`).

## TL;DR

For every feature:

1. Create a subfolder `app/docs/{MARK}-{Suffix}/`.
   - `{MARK}` = uppercase mark, default `FEAT-<AREA>-<NNN>`. Dots become dashes in the folder name.
   - `{Suffix}` = short PascalCase English title (e.g. `HandlingUnits`).
2. Inside, create at minimum:
   - `technical-documentation.md` — developers, English. Source/legacy reference is `N/A (greenfield)`.
   - `getting-started-english.md` — end users, English.
   - `getting-started-<lang>.md` — end users, customer language.
3. Optionally `test-plan-unit-test.md`, `test-plan-integration-test.md`, `todo.md`.

There is no `nav2bc-object-mapping.md` — this is a greenfield app with no NAV ancestor.

## H1 convention

Every `.md` file's H1 is exactly `# {MARK} - {Title}` — the dotted form of the mark, no
trailing suffix (no "Getting Started"). The deliverable tooling splits on the first ` - `.

## Getting-started files are for end users only

No object names or IDs, no procedure or field names, no permission-set identifiers, no AL
or API jargon. Refer to everything by the caption the user sees. Anything technical belongs
in `technical-documentation.md`.

The master index is [getting-started-english.md](getting-started-english.md) — add each
feature's link there as the feature ships.

## Planning documents

These are not feature documentation and follow no `{MARK}` convention:

- [agent-instructions/](agent-instructions/) — one ready-to-paste system prompt per MCP configuration
- [implementation-plan.md](implementation-plan.md) — build sequence, per-feature cost, and the discovery that gates it
- [modules.md](modules.md) — candidate module map and object ID allocation
- [gap-analysis.md](gap-analysis.md) — method for turning candidate scope into real scope
- [inventory-posting.md](inventory-posting.md) — the shared posting engine two features use, and why it is not a feature
- [warehouse-registration.md](warehouse-registration.md) — how a finished job reaches Business Central's own bins, and why it is not a feature
- [location-configuration.md](location-configuration.md) — which Business Central location settings this app works with, and which it refuses

## Customer-facing legal text

Drafts for the pages `app.json` links to. Neither is published — the manifest points at a
domain with no site on it, which is a recorded and accepted debt.

- [privacy-statement.md](privacy-statement.md) — draft content for the privacy page
- [eula.md](eula.md) — draft content for the EULA page. **Unreviewed, and two clauses are
  deliberately unfilled.** Repo-level copyright is [LICENSE](../../LICENSE) instead, which is
  a different document for a different audience: the EULA is the agreement with the customer
  who installs the app, the licence file is the notice to anyone who can read the source

`FEAT-CORE-001-Foundation/` was **back-filled**: the foundation shipped in PRs #5–#7 without
documentation, and everything except the role centre section was written afterwards by reading the
objects rather than from a design record. It says so at the top. That is the honest state of it, and
it is worth knowing before treating any "why" in it as a decision log.
