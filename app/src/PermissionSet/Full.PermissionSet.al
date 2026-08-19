namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Integration;
using WarehouseAdvanced.Labelling;
using WarehouseAdvanced.MobileDevice;
using WarehouseAdvanced.Packing;
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
        tabledata "WHA Label Setup" = RIMD,
        tabledata "WHA Pack Setup" = RIMD,
        tabledata "WHA Pack Station" = RIMD,
        tabledata "WHA Pack Session" = RIMD,
        tabledata "WHA Demo Data" = RIMD;
}
