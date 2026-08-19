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

- [implementation-plan.md](implementation-plan.md) — build sequence, per-feature cost, and the discovery that gates it
- [modules.md](modules.md) — candidate module map and object ID allocation
- [gap-analysis.md](gap-analysis.md) — method for turning candidate scope into real scope
