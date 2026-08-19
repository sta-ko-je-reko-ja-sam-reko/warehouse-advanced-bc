namespace WarehouseAdvanced.Core;

using WarehouseAdvanced.Counting;
using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Integration;
using WarehouseAdvanced.Labelling;
using WarehouseAdvanced.MobileDevice;
using WarehouseAdvanced.Packing;
using WarehouseAdvanced.QualityHold;
using WarehouseAdvanced.Replenishment;
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
    value(7; WHAPacking)
    {
        Caption = 'Packing';
        Implementation = "WHA IFeatureSetup" = "WHA Pack Feature Setup";
    }
    value(8; WHAReplenishment)
    {
        Caption = 'Replenishment';
        Implementation = "WHA IFeatureSetup" = "WHA Repl. Feature Setup";
    }
    value(9; WHACounting)
    {
        Caption = 'Counting';
        Implementation = "WHA IFeatureSetup" = "WHA Count Feature Setup";
    }
    value(10; WHAQualityHold)
    {
        Caption = 'Quality hold';
        Implementation = "WHA IFeatureSetup" = "WHA QC Feature Setup";
    }
}
