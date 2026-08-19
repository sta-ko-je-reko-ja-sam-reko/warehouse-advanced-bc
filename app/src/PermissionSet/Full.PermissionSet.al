namespace WarehouseAdvanced.Core;

permissionset 50002 "WHA Full"
{
    Assignable = true;
    Caption = 'Warehouse Advanced - Full', Locked = true;
    IncludedPermissionSets = "WHA Objects";

    Permissions =
        tabledata "WHA Warehouse Setup" = RIMD;
}
