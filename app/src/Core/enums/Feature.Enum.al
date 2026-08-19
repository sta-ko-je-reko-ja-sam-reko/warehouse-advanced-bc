namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Integration;
using WarehouseAdvanced.Labelling;
using WarehouseAdvanced.MobileDevice;
using WarehouseAdvanced.WaveManagement;

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
    value(4; WHAMobileDevice)
    {
        Caption = 'Handheld';
        Implementation = "WHA IFeatureSetup" = "WHA RF Feature Setup";
    }
    value(5; WHAWaveManagement)
    {
        Caption = 'Wave management';
        Implementation = "WHA IFeatureSetup" = "WHA Wave Feature Setup";
    }
    value(6; WHALabelling)
    {
        Caption = 'Labelling';
        Implementation = "WHA IFeatureSetup" = "WHA Label Feature Setup";
    }
}
