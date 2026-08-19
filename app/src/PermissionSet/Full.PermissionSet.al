namespace WarehouseAdvanced.Core;

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
        tabledata "WHA Demo Data" = RIMD;
}
