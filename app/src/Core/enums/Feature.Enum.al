namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Integration;

enum 50000 "WHA Feature" implements "WHA IFeatureSetup"
{
    Caption = 'Warehouse advanced feature';
    Extensible = true;
    DefaultImplementation = "WHA IFeatureSetup" = "WHA Default Feature Setup";

    value(0; WHANone)
    {
        Caption = 'None';
    }
    value(1; WHAHandlingUnits)
    {
        Caption = 'Handling units';
        Implementation = "WHA IFeatureSetup" = "WHA HU Feature Setup";
    }
    value(2; WHADirectedWork)
    {
        Caption = 'Directed work';
        Implementation = "WHA IFeatureSetup" = "WHA Task Feature Setup";
    }
    value(3; WHAIntegration)
    {
        Caption = 'Integration';
        Implementation = "WHA IFeatureSetup" = "WHA Int. Feature Setup";
    }
}
