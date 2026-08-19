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

permissionset 50002 "WHA Full"
{
    Assignable = true;
    Caption = 'Warehouse Advanced - Full', Locked = true;
    IncludedPermissionSets = "WHA Objects";

    Permissions =
        tabledata "WHA Warehouse Setup" = RIMD,
        tabledata "WHA Handling Unit Setup" = RIMD,
        tabledata "WHA Handling Unit" = RIMD,
        tabledata "WHA Handling Unit Line" = RIMD,
        tabledata "WHA Warehouse Task Setup" = RIMD,
        tabledata "WHA Warehouse Task" = RIMD,
        tabledata "WHA Integration Setup" = RIMD,
        tabledata "WHA Integration Message" = RIMD,
        tabledata "WHA RF Setup" = RIMD,
        tabledata "WHA RF Device" = RIMD,
        tabledata "WHA Wave Setup" = RIMD,
        tabledata "WHA Wave" = RIMD,
        tabledata "WHA Wave Template" = RIMD,
        tabledata "WHA Label Setup" = RIMD,
        tabledata "WHA Pack Setup" = RIMD,
        tabledata "WHA Pack Station" = RIMD,
        tabledata "WHA Pack Session" = RIMD,
        tabledata "WHA Repl. Setup" = RIMD,
        tabledata "WHA Replenishment Rule" = RIMD,
        tabledata "WHA Count Setup" = RIMD,
        tabledata "WHA Count Sheet" = RIMD,
        tabledata "WHA Count Sheet Line" = RIMD,
        tabledata "WHA Quality Hold Setup" = RIMD,
        tabledata "WHA Quality Hold" = RIMD,
        tabledata "WHA Labour Setup" = RIMD,
        tabledata "WHA Labour Standard" = RIMD,
        tabledata "WHA Labour Entry" = RIMD,
        tabledata "WHA Slotting Setup" = RIMD,
        tabledata "WHA Item Velocity" = RIMD,
        tabledata "WHA Slotting Proposal" = RIMD,
        tabledata "WHA Dock Setup" = RIMD,
        tabledata "WHA Dock Door" = RIMD,
        tabledata "WHA Yard Position" = RIMD,
        tabledata "WHA Dock Appointment" = RIMD,
        tabledata "WHA Analytics Setup" = RIMD,
        tabledata "WHA KPI Snapshot" = RIMD,
        tabledata "WHA Demo Data" = RIMD;
}
