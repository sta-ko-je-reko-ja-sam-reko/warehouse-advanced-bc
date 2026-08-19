namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;

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
        tabledata "WHA Demo Data" = RIMD;
}
