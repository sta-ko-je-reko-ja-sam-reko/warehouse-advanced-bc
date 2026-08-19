namespace WarehouseAdvanced.Labelling;

using System.IO;
using WarehouseAdvanced.HandlingUnit;

codeunit 50603 "WHA Demo Label"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-LBL', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Labelling';
        DemoPrefixTok: Label '0801234', Locked = true;

    /// <summary>
    /// Sets up a sample GS1 company prefix and labels the sample handling units that do not already
    /// carry a code. Idempotent — a unit that has a code keeps the one it has, because a label is
    /// printed and stuck on and cannot be taken back.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Label Setup";
        LabelFeatureSetup: Codeunit "WHA Label Feature Setup";
    begin
        LabelFeatureSetup.EnsureSetup(Setup);

        if Setup."GS1 Company Prefix" = '' then begin
            Setup.Validate("GS1 Company Prefix", CopyStr(DemoPrefixTok, 1, MaxStrLen(Setup."GS1 Company Prefix")));
            Setup.Modify(true);
        end;

        LabelDemoUnits();

        CreateConfigPackage();
    end;

    local procedure LabelDemoUnits()
    var
        HandlingUnit: Record "WHA Handling Unit";
        LabelMgt: Codeunit "WHA Label Mgt.";
    begin
        HandlingUnit.SetFilter("No.", 'DEMO-HU-*');
        HandlingUnit.SetRange(SSCC, '');
        HandlingUnit.SetFilter(Status, '<>%1', HandlingUnit.Status::WHAShipped);
        if not HandlingUnit.FindSet() then
            exit;

        repeat
            LabelMgt.AssignTo(HandlingUnit);
        until HandlingUnit.Next() = 0;
    end;

    local procedure CreateConfigPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        if ConfigPackage.Get(PackageCodeTok) then
            exit;

        ConfigPackageMgt.InsertPackage(ConfigPackage, PackageCodeTok, CopyStr(PackageNameLbl, 1, 50), true);
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Handling Unit");
    end;
}
