namespace WarehouseAdvanced.MobileDevice;

using Microsoft.Inventory.Location;
using System.IO;

codeunit 50103 "WHA Demo RF Device"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-RF', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Mobile Device';
        TruckDescLbl: Label 'Forklift terminal - goods in';
        HandheldDescLbl: Label 'Handheld scanner - picking';
        SpareDescLbl: Label 'Spare scanner - in the charging rack';

    /// <summary>
    /// Seeds sample handheld devices, covering a device tied to a location, one that works anywhere, and
    /// a blocked one. Idempotent — re-running creates nothing new. Also builds this feature's RapidStart
    /// configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA RF Setup";
        RFFeatureSetup: Codeunit "WHA RF Feature Setup";
    begin
        RFFeatureSetup.EnsureSetup(Setup);

        InsertDevice('DEMO-RF-001', TruckDescLbl, FirstLocation(), false);
        InsertDevice('DEMO-RF-002', HandheldDescLbl, '', false);
        InsertDevice('DEMO-RF-003', SpareDescLbl, FirstLocation(), true);

        CreateConfigPackage();
    end;

    local procedure InsertDevice(DeviceCode: Code[20]; DeviceDescription: Text[100]; LocationCode: Code[10]; IsBlocked: Boolean)
    var
        RFDevice: Record "WHA RF Device";
    begin
        if RFDevice.Get(DeviceCode) then
            exit;

        RFDevice.Init();
        RFDevice."Code" := DeviceCode;
        RFDevice.Validate(Description, DeviceDescription);
        if LocationCode <> '' then
            RFDevice.Validate("Default Location Code", LocationCode);
        RFDevice.Validate(Blocked, IsBlocked);
        RFDevice.Insert(true);
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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA RF Device");
    end;
}
