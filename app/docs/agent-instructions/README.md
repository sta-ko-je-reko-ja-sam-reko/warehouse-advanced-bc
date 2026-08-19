# Agent instructions

Business Central has **no field or API that carries agent instructions** on an MCP configuration
(as of BC 28.2, `MCP Config` exposes only `CreateConfiguration(Name; Description[250])` plus tool
and permission calls). So the instructions cannot live in BC — they are delivered on the agent side.

Each file here is a **ready-to-paste system prompt** for the single Copilot agent wired to one MCP
configuration. One configuration ↔ one agent ↔ one file.

## Index

| MCP configuration (in BC) | API group | Instructions | Paste into |
|---|---|---|---|
| `Warehouse Advanced - Handling Units` | `handlingUnit` | [WarehouseAdvanced-HandlingUnits.md](WarehouseAdvanced-HandlingUnits.md) | The agent bound to the Handling Units configuration |
| `Warehouse Advanced - Demo Handling Units` | `demoHandlingUnit` | [WarehouseAdvanced-Demo-HandlingUnits.md](WarehouseAdvanced-Demo-HandlingUnits.md) | The agent bound to the Demo Handling Units configuration |
| `Warehouse Advanced - Directed Work` | `directedWork` | [WarehouseAdvanced-DirectedWork.md](WarehouseAdvanced-DirectedWork.md) | The agent bound to the Directed Work configuration |
| `Warehouse Advanced - Demo Directed Work` | `demoDirectedWork` | [WarehouseAdvanced-Demo-DirectedWork.md](WarehouseAdvanced-Demo-DirectedWork.md) | The agent bound to the Demo Directed Work configuration |
| `Warehouse Advanced - Integration` | `integration` | [WarehouseAdvanced-Integration.md](WarehouseAdvanced-Integration.md) | The agent bound to the Integration configuration |
| `Warehouse Advanced - Demo Integration` | `demoIntegration` | [WarehouseAdvanced-Demo-Integration.md](WarehouseAdvanced-Demo-Integration.md) | The agent bound to the Demo Integration configuration |
| `Warehouse Advanced - Mobile Device` | `mobileDevice` | [WarehouseAdvanced-MobileDevice.md](WarehouseAdvanced-MobileDevice.md) | The agent bound to the Mobile Device configuration |
| `Warehouse Advanced - Demo Mobile Device` | `demoMobileDevice` | [WarehouseAdvanced-Demo-MobileDevice.md](WarehouseAdvanced-Demo-MobileDevice.md) | The agent bound to the Demo Mobile Device configuration |
| `Warehouse Advanced - Wave Management` | `waveManagement` | [WarehouseAdvanced-WaveManagement.md](WarehouseAdvanced-WaveManagement.md) | The agent bound to the Wave Management configuration |
| `Warehouse Advanced - Demo Wave Management` | `demoWaveManagement` | [WarehouseAdvanced-Demo-WaveManagement.md](WarehouseAdvanced-Demo-WaveManagement.md) | The agent bound to the Demo Wave Management configuration |
| `Warehouse Advanced - Labelling` | `labelling` | [WarehouseAdvanced-Labelling.md](WarehouseAdvanced-Labelling.md) | The agent bound to the Labelling configuration |
| `Warehouse Advanced - Demo Labelling` | `demoLabelling` | [WarehouseAdvanced-Demo-Labelling.md](WarehouseAdvanced-Demo-Labelling.md) | The agent bound to the Demo Labelling configuration |
| `Warehouse Advanced - Packing` | `packing` | [WarehouseAdvanced-Packing.md](WarehouseAdvanced-Packing.md) | The agent bound to the Packing configuration |
| `Warehouse Advanced - Demo Packing` | `demoPacking` | [WarehouseAdvanced-Demo-Packing.md](WarehouseAdvanced-Demo-Packing.md) | The agent bound to the Demo Packing configuration |
| `Warehouse Advanced - Replenishment` | `replenishment` | [WarehouseAdvanced-Replenishment.md](WarehouseAdvanced-Replenishment.md) | The agent bound to the Replenishment configuration |
| `Warehouse Advanced - Demo Replenishment` | `demoReplenishment` | [WarehouseAdvanced-Demo-Replenishment.md](WarehouseAdvanced-Demo-Replenishment.md) | The agent bound to the Demo Replenishment configuration |
| `Warehouse Advanced - Counting` | `counting` | [WarehouseAdvanced-Counting.md](WarehouseAdvanced-Counting.md) | The agent bound to the Counting configuration |
| `Warehouse Advanced - Demo Counting` | `demoCounting` | [WarehouseAdvanced-Demo-Counting.md](WarehouseAdvanced-Demo-Counting.md) | The agent bound to the Demo Counting configuration |
| `Warehouse Advanced - Quality Hold` | `qualityHold` | [WarehouseAdvanced-QualityHold.md](WarehouseAdvanced-QualityHold.md) | The agent bound to the Quality Hold configuration |
| `Warehouse Advanced - Demo Quality Hold` | `demoQualityHold` | [WarehouseAdvanced-Demo-QualityHold.md](WarehouseAdvanced-Demo-QualityHold.md) | The agent bound to the Demo Quality Hold configuration |
| `Warehouse Advanced - Labour Management` | `labourManagement` | [WarehouseAdvanced-LabourManagement.md](WarehouseAdvanced-LabourManagement.md) | The agent bound to the Labour Management configuration |
| `Warehouse Advanced - Demo Labour Management` | `demoLabourManagement` | [WarehouseAdvanced-Demo-LabourManagement.md](WarehouseAdvanced-Demo-LabourManagement.md) | The agent bound to the Demo Labour Management configuration |
| `Warehouse Advanced - Slotting` | `slotting` | [WarehouseAdvanced-Slotting.md](WarehouseAdvanced-Slotting.md) | The agent bound to the Slotting configuration |
| `Warehouse Advanced - Demo Slotting` | `demoSlotting` | [WarehouseAdvanced-Demo-Slotting.md](WarehouseAdvanced-Demo-Slotting.md) | The agent bound to the Demo Slotting configuration |
| `Warehouse Advanced - Dock and Yard` | `dockYard` | [WarehouseAdvanced-DockYard.md](WarehouseAdvanced-DockYard.md) | The agent bound to the Dock and Yard configuration |
| `Warehouse Advanced - Demo Dock and Yard` | `demoDockYard` | [WarehouseAdvanced-Demo-DockYard.md](WarehouseAdvanced-Demo-DockYard.md) | The agent bound to the Demo Dock and Yard configuration |
| `Warehouse Advanced - Analytics` | `analytics` | [WarehouseAdvanced-Analytics.md](WarehouseAdvanced-Analytics.md) | The agent bound to the Analytics configuration |
| `Warehouse Advanced - Demo Analytics` | `demoAnalytics` | [WarehouseAdvanced-Demo-Analytics.md](WarehouseAdvanced-Demo-Analytics.md) | The agent bound to the Demo Analytics configuration |

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
configurations are **per feature** — one each, and the foundation owns none, because it holds no data
worth exposing — so no single `FEAT-` folder is their home. They live at the docs root instead, with
the index above.
