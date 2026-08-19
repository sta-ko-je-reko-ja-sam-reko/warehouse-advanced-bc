namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;

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
        codeunit "WHA Upgrade" = X,
        codeunit "WHA MCP Setup" = X,
        table "WHA Handling Unit Setup" = X,
        table "WHA Handling Unit" = X,
        table "WHA Handling Unit Line" = X,
        page "WHA Handling Unit Setup" = X,
        page "WHA Handling Unit Card" = X,
        page "WHA Handling Units" = X,
        page "WHA API Handling Unit" = X,
        page "WHA Handling Unit Lines" = X,
        page "WHA API Handling Unit Line" = X,
        codeunit "WHA Handling Unit Logic" = X,
        codeunit "WHA HU Line Logic" = X,
        codeunit "WHA HU Feature Setup" = X,
        codeunit "WHA HU App Area Sub." = X,
        table "WHA Demo Data" = X,
        codeunit "WHA Demo Handling Unit" = X,
        page "WHA API Demo Handling Unit" = X,
        table "WHA Warehouse Task Setup" = X,
        table "WHA Warehouse Task" = X,
        page "WHA Warehouse Task Setup" = X,
        page "WHA Warehouse Task Card" = X,
        page "WHA Warehouse Tasks" = X,
        page "WHA API Warehouse Task" = X,
        codeunit "WHA Warehouse Task Logic" = X,
        codeunit "WHA Task Feature Setup" = X,
        codeunit "WHA Task App Area Sub." = X,
        codeunit "WHA Demo Warehouse Task" = X,
        page "WHA API Demo Warehouse Task" = X;
}
