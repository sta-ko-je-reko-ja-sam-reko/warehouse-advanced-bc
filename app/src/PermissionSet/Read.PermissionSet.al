namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.HandlingUnit;

permissionset 50001 "WHA Read"
{
    Assignable = true;
    Caption = 'Warehouse Advanced - Read', Locked = true;
    IncludedPermissionSets = "WHA Objects";

    Permissions =
        tabledata "WHA Warehouse Setup" = R,
        tabledata "WHA Handling Unit Setup" = R,
        tabledata "WHA Handling Unit" = R;
}
