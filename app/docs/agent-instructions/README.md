# Agent instructions

Business Central has **no field or API that carries agent instructions** on an MCP configuration
(as of BC 28.2, `MCP Config` exposes only `CreateConfiguration(Name; Description[250])` plus tool
and permission calls). So the instructions cannot live in BC — they are delivered on the agent side.

Each file here is a **ready-to-paste system prompt** for the single Copilot agent wired to one MCP
configuration. One configuration ↔ one agent ↔ one file.

## Index

| MCP configuration (in BC) | API group | Instructions | Paste into |
|---|---|---|---|
| `Warehouse Advanced - Core` | `core` | [WarehouseAdvanced-Core.md](WarehouseAdvanced-Core.md) | The agent bound to the Core configuration |
| `Warehouse Advanced - Handling Units` | `handlingUnit` | [WarehouseAdvanced-HandlingUnits.md](WarehouseAdvanced-HandlingUnits.md) | The agent bound to the Handling Units configuration |
| `Warehouse Advanced - Demo Handling Units` | `demoHandlingUnit` | [WarehouseAdvanced-Demo-HandlingUnits.md](WarehouseAdvanced-Demo-HandlingUnits.md) | The agent bound to the Demo Handling Units configuration |
| `Warehouse Advanced - Directed Work` | `directedWork` | [WarehouseAdvanced-DirectedWork.md](WarehouseAdvanced-DirectedWork.md) | The agent bound to the Directed Work configuration |
| `Warehouse Advanced - Demo Directed Work` | `demoDirectedWork` | [WarehouseAdvanced-Demo-DirectedWork.md](WarehouseAdvanced-Demo-DirectedWork.md) | The agent bound to the Demo Directed Work configuration |

**Demo importers are deliberately in their own configurations and their own API groups**, so a
"load sample data" agent can be given the importer *without* also getting the functional write
tools — and vice versa.

## How an administrator uses these

1. In Business Central, search for **MCP Configurations**. The app creates and activates its
   configurations on install and upgrade, so they are already there.
2. Open the configuration and copy its connection string.
3. In Copilot Studio, create an agent and connect it to that configuration.
4. Open the matching file above and paste its contents into the agent's instructions.

Repeat per configuration — do **not** point one agent at several configurations and merge the
instructions, because each file is scoped to exactly the tools its own configuration exposes.

## Keeping these in sync — this is a gate, not a suggestion

Adding, removing, or renaming a tool in a configuration is **not done** until that configuration's
file is updated in the same change. Adding a configuration means adding a file and a row above.
`feature-ready.md` checks this.

## Deviation from the template

`_patterns/mcp-configuration-instructions.md` places these at
`docs/FEAT-<MCP>/agent-instructions/`, assuming one feature owns the MCP surface. Here the
configurations are **per module** — the foundation owns one, each feature owns its own — so no
single `FEAT-` folder is their home. They live at the docs root instead, with the index above.
