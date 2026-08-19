namespace WarehouseAdvanced.Slotting;

using Microsoft.Inventory.Location;
using System.IO;

codeunit 50304 "WHA Demo Slotting"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-SLOT', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Slotting';

    /// <summary>
    /// Runs the analysis and the proposals against whatever finished picking the company already has, at
    /// the first location that has any. There is no sample data of its own to seed: a velocity is a
    /// statement about work that was actually done, and inventing one would produce a class nobody could
    /// check. Idempotent — an analysis replaces the previous answer, and a proposal is not repeated while
    /// an open one exists. Also builds this feature's RapidStart configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Slotting Setup";
        SlotFeatureSetup: Codeunit "WHA Slot. Feature Setup";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
        LocationCode: Code[10];
    begin
        SlotFeatureSetup.EnsureSetup(Setup);

        LocationCode := FirstLocation();
        if LocationCode <> '' then begin
            SlottingMgt.Analyse(LocationCode, 0D, 0D);
            SlottingMgt.Propose(LocationCode);
        end;

        CreateConfigPackage();
    end;

    local procedure FirstLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetLoadFields(Code);
        Location.SetRange("Use As In-Transit", false);
        if not Location.FindFirst() then
            exit('');
        exit(Location.Code);
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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Item Velocity");
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Slotting Proposal");
    end;
}
