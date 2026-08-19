namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Integration;

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
        tabledata "WHA Demo Data" = R;
}
