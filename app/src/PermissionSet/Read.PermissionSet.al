namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.Analytics;
using WarehouseAdvanced.Counting;
using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.DockYard;
using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Integration;
using WarehouseAdvanced.Labelling;
using WarehouseAdvanced.LabourManagement;
using WarehouseAdvanced.MobileDevice;
using WarehouseAdvanced.Packing;
using WarehouseAdvanced.QualityHold;
using WarehouseAdvanced.Replenishment;
using WarehouseAdvanced.Slotting;
using WarehouseAdvanced.WaveManagement;

permissionset 50001 "WHA Read"
{
    Assignable = true;
    Caption = 'Warehouse Advanced - Read', Locked = true;
    IncludedPermissionSets = "WHA Objects";

    Permissions =
        tabledata "WHA Warehouse Setup" = R,
        tabledata "WHA Handling Unit Setup" = R,
        tabledata "WHA Handling Unit" = R,
        tabledata "WHA Handling Unit Line" = R,
        tabledata "WHA Warehouse Task Setup" = R,
        tabledata "WHA Warehouse Task" = R,
        tabledata "WHA Integration Setup" = R,
        tabledata "WHA Integration Message" = R,
        tabledata "WHA RF Setup" = R,
        tabledata "WHA RF Device" = R,
        tabledata "WHA Wave Setup" = R,
        tabledata "WHA Wave" = R,
        tabledata "WHA Wave Template" = R,
        tabledata "WHA Label Setup" = R,
        tabledata "WHA Pack Setup" = R,
        tabledata "WHA Pack Station" = R,
        tabledata "WHA Pack Session" = R,
        tabledata "WHA Repl. Setup" = R,
        tabledata "WHA Replenishment Rule" = R,
        tabledata "WHA Count Setup" = R,
        tabledata "WHA Count Sheet" = R,
        tabledata "WHA Count Sheet Line" = R,
        tabledata "WHA Quality Hold Setup" = R,
        tabledata "WHA Quality Hold" = R,
        tabledata "WHA Labour Setup" = R,
        tabledata "WHA Labour Standard" = R,
        tabledata "WHA Labour Entry" = R,
        tabledata "WHA Slotting Setup" = R,
        tabledata "WHA Item Velocity" = R,
        tabledata "WHA Slotting Proposal" = R,
        tabledata "WHA Dock Setup" = R,
        tabledata "WHA Dock Door" = R,
        tabledata "WHA Yard Position" = R,
        tabledata "WHA Dock Appointment" = R,
        tabledata "WHA Analytics Setup" = R,
        tabledata "WHA KPI Snapshot" = R,
        tabledata "WHA Demo Data" = R;
}
