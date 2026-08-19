# FEAT-HU-001 - Handling Units

## Source/legacy reference

N/A (greenfield).

> **Scope note.** This feature was built from the candidate catalogue in
> [../implementation-plan.md](../implementation-plan.md), **not** from a signed capability register.
> The Qguar capability discovery (Phase 0) has not been run. Handling units were chosen first
> because most of the catalogue depends on them — if this customer does not identify pallets, this
> feature and much of what sits above it need re-scoping.

## Business process

Standard Business Central tracks inventory by item, lot and serial number, and by bin. It has no
first-class notion of the **physical unit** those goods sit on — a pallet, cage or carton that is
moved, stored and shipped as one thing.

This feature adds that unit:

1. A handling unit is created and receives a number from the foundation number series.
2. It is given a location and, optionally, a bin.
3. It may be placed inside another handling unit. Moving the outer unit moves everything within it.
4. It carries an SSCC for labelling and for identifying the unit to trading partners.
5. It moves through a life cycle: open while being built, closed when ready, shipped once despatched.

Nesting is configurable — it can be switched off entirely, or limited to a maximum depth.

### Delivered in this segment

The handling unit entity, its nesting rules, and its enablement. **Contents are not modelled yet**:
a handling unit does not yet know which item quantities it holds. That is the next segment and is
what makes the unit useful for picking and shipping.

## Data model

| Table | ID | Purpose |
|---|---|---|
| `WHA Handling Unit Setup` | 50050 | Single-record feature setup: enablement and nesting rules |
| `WHA Handling Unit` | 50051 | The unit itself |

### `WHA Handling Unit`

| Field | Type | Notes |
|---|---|---|
| `No.` | `Code[20]` | Primary key, assigned from the foundation number series |
| `SSCC` | `Code[20]` | Serial shipping container code; secondary key for lookup |
| `Description` | `Text[100]` | |
| `Location Code` | `Code[10]` | `TableRelation = Location`. Changing it clears `Bin Code` |
| `Bin Code` | `Code[20]` | Filtered to the unit's location |
| `Parent No.` | `Code[20]` | Self-relation; the unit this one sits inside |
| `Status` | `Enum "WHA Handling Unit Status"` | Open / Closed / Shipped |
| `Nested Unit Count` | `Integer` | FlowField counting direct children |

Keys: `PK` on `No.` (clustered), plus `Parent No.`, `Location Code + Bin Code`, and `SSCC`.

### Number series

The handling unit number series lives on the **foundation** setup (`WHA Warehouse Setup."Handling
Unit Nos."`), not on this feature's setup. Foundation owns cross-cutting numbering, and the guided
setup's foundation step is what creates the `WHA-HU` series. Inserting a handling unit with no
number errors if that series is unset.

## Objects

| Object | Type | ID | File |
|---|---|---|---|
| `WHA Handling Unit Setup` | table | 50050 | `app/src/HandlingUnit/tables/HandlingUnitSetup.Table.al` |
| `WHA Handling Unit` | table | 50051 | `app/src/HandlingUnit/tables/HandlingUnit.Table.al` |
| `WHA Handling Unit Status` | enum | 50050 | `app/src/HandlingUnit/enums/HandlingUnitStatus.Enum.al` |
| `WHA IHandlingUnit` | interface | — | `app/src/HandlingUnit/interfaces/IHandlingUnit.Interface.al` |
| `WHA Handling Unit Logic` | codeunit | 50050 | `app/src/HandlingUnit/codeunits/HandlingUnitLogic.Codeunit.al` |
| `WHA HU Feature Setup` | codeunit | 50051 | `app/src/HandlingUnit/codeunits/HUFeatureSetup.Codeunit.al` |
| `WHA HU App Area Sub.` | codeunit | 50052 | `app/src/HandlingUnit/codeunits/HUAppAreaSub.Codeunit.al` |
| `WHA Appl. Area Setup` | tableextension | 50050 | `app/src/HandlingUnit/tableextensions/ApplAreaSetup.TableExt.al` |
| `WHA Handling Unit Setup` | page | 50050 | `app/src/HandlingUnit/pages/HandlingUnitSetup.Page.al` |
| `WHA Handling Unit Card` | page | 50051 | `app/src/HandlingUnit/pages/HandlingUnitCard.Page.al` |
| `WHA Handling Units` | page | 50052 | `app/src/HandlingUnit/pages/HandlingUnits.Page.al` |
| `WHA API Handling Unit` | page | 50053 | `app/src/HandlingUnit/pages/APIHandlingUnit.Page.al` |
| `WHA Handling Unit Tests` | codeunit | 51000 | `test/src/codeunits/HandlingUnit.Test.Codeunit.al` |

All in namespace `WarehouseAdvanced.HandlingUnit`, from the reserved block `50050..50099`.

## Logic

All table triggers and field validations delegate a single line to `Logic()`, resolved through
`WHA IHandlingUnit` with a public `Define()` for injection. The rules live in
`WHA Handling Unit Logic`:

| Operation | Behaviour |
|---|---|
| `Trigger_OnInsert` | Assigns the number from the foundation series; errors if it is unset |
| `Trigger_OnDelete` | Refuses to delete a unit that still holds nested units |
| `Validate_LocationCode` | Clears the bin when the location actually changes |
| `Validate_ParentNo` | Rejects self-parenting, cycles, nesting when disabled, and exceeding max depth |
| `GetNestingDepth` | Walks the parent chain, bounded at 100 hops |

Both hierarchy walks are **bounded by a guard counter**, so pre-existing cyclic data cannot hang a
session — the cycle check prevents new cycles, but the guard protects against data that arrived
another way (a direct API write before validation, or an import).

## Enablement

Per `_patterns/feature-setup-and-toggle.md`:

- `WHA Feature` gained value `WHAHandlingUnits`, bound to `WHA HU Feature Setup` via the interface.
  That is what registers the guided setup step and answers `IsEnabled` — **no Core code changed.**
- `Application Area Setup` gained `WHA Handling Units`, giving the tag `WHAHandlingUnits`.
- `WHA HU App Area Sub.` sets that boolean from the feature's `Enabled` on experience-tier refresh,
  subscribing with `SkipOnMissingLicense`/`SkipOnMissingPermission` both `true`.
- **The setup page is `ApplicationArea = All`**; the card and list carry `WHAHandlingUnits`. The
  `Enabled` field inherits `All` while the nesting fields take the feature area, so the switch stays
  reachable when the feature is off.
- The API page guards `OnInsertRecord`/`OnModifyRecord`/`OnDeleteRecord` with `CheckEnabled`, because
  application areas do not reach the API path. Reads stay open.

## MCP configuration

The API page is exposed to agents through its own MCP configuration, created and activated on
install and upgrade:

| Configuration | API group | Tool | Agent may |
|---|---|---|---|
| `Warehouse Advanced - Handling Units` | `handlingUnit` | `WHA API Handling Unit` | read, create, modify, delete |

Registration goes through `WHA IFeatureSetup.RegisterMcpConfiguration`, so the feature owns its
configuration and Core needs no per-feature knowledge. `WHA MCP Setup` supplies the idempotent
helpers (`EnsureConfiguration`, `EnsureApiTool`, `Activate`), all keyed on the configuration name,
so repeated install/upgrade runs neither duplicate nor reset anything.

Business Central has no field that carries agent instructions, so they ship as a companion document:
[../agent-instructions/WarehouseAdvanced-HandlingUnits.md](../agent-instructions/WarehouseAdvanced-HandlingUnits.md).
**Changing the tools in this configuration is not done until that file is updated in the same
change.**

## Tests

`WHA Handling Unit Tests` (codeunit 51000) covers the segment's logic directly, with no database
writes — the procedures take records by reference, so unsaved records can be passed in:

| Test | Asserts |
|---|---|
| `LocationChangeClearsBin` | Bin is cleared when the location changes |
| `SameLocationKeepsBin` | Bin survives when the location is unchanged |
| `SelfParentIsRejected` | Placing a unit inside itself errors |
| `ClearingParentIsAllowed` | Removing a unit from its parent is never blocked |
| `TopLevelUnitHasZeroDepth` | A unit with no parent is at depth zero |

Cycle detection and depth limits need persisted parent chains, so they belong in the integration
tests that accompany the contents segment.

## Not done

- **Contents.** The unit holds no item quantities yet.
- **Demo data**, the `[ServiceEnabled] ImportDemoData` API, its **own** demo MCP configuration, and
  the RapidStart package. `ApplyChoices` accepts the sample-data opt-in and currently does nothing
  with it. Note the functional MCP configuration below is separate — the demo importer gets its own,
  so importers can be routed to a different agent.
- **Getting-started in the customer language** — the language has not been confirmed.
- **SSCC generation.** The field exists; generating a valid GS1 check digit belongs to `FEAT-LBL-001`.
