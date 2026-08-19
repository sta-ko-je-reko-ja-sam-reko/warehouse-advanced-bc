namespace WarehouseAdvanced.Core;

permissionset 50001 "WHA Read"
{
    Assignable = true;
    Caption = 'Warehouse Advanced - Read', Locked = true;
    IncludedPermissionSets = "WHA Objects";

    Permissions =
        tabledata "WHA Warehouse Setup" = R;
}
