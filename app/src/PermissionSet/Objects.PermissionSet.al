namespace WarehouseAdvanced.Core;

permissionset 50000 "WHA Objects"
{
    Assignable = false;
    Caption = 'Warehouse Advanced - Objects', Locked = true;

    Permissions =
        table "WHA Warehouse Setup" = X,
        table "WHA Setup Step" = X,
        page "WHA Warehouse Setup" = X,
        page "WHA Setup Hub" = X,
        page "WHA Feature Setup Wizard" = X,
        page "WHA API Warehouse Setup" = X,
        codeunit "WHA Warehouse Setup Logic" = X,
        codeunit "WHA Default Feature Setup" = X,
        codeunit "WHA Feature Mgt." = X,
        codeunit "WHA Guided Setup" = X,
        codeunit "WHA Install" = X,
        codeunit "WHA Upgrade" = X;
}
