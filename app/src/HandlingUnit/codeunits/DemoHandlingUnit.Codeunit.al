namespace WarehouseAdvanced.HandlingUnit;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.IO;

codeunit 50053 "WHA Demo Handling Unit"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-HU', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Handling Units';
        PalletDescLbl: Label 'Euro pallet - electronics';
        CartonDescLbl: Label 'Carton - accessories';
        CageDescLbl: Label 'Cage - customer returns';
        ShippedDescLbl: Label 'Pallet - despatched to customer';

    /// <summary>
    /// Seeds sample handling units that exercise every status, nesting, the SSCC field and the nested
    /// unit count. Idempotent — re-running creates nothing new. Also builds this feature's RapidStart
    /// configuration package, so the package exists only when the user chose to import sample data.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Handling Unit Setup";
        HUFeatureSetup: Codeunit "WHA HU Feature Setup";
        Status: Enum "WHA Handling Unit Status";
    begin
        HUFeatureSetup.EnsureSetup(Setup);

        InsertUnit('DEMO-HU-001', PalletDescLbl, '380123456789012340', '', Status::WHAOpen);
        InsertUnit('DEMO-HU-002', CartonDescLbl, '', 'DEMO-HU-001', Status::WHAOpen);
        InsertUnit('DEMO-HU-003', CageDescLbl, '', '', Status::WHAClosed);
        InsertUnit('DEMO-HU-004', ShippedDescLbl, '380123456789012357', '', Status::WHAShipped);

        InsertSampleContents();

        CreateConfigPackage();
    end;

    local procedure InsertUnit(UnitNo: Code[20]; UnitDescription: Text[100]; Sscc: Code[20]; ParentNo: Code[20]; UnitStatus: Enum "WHA Handling Unit Status")
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        if HandlingUnit.Get(UnitNo) then
            exit;

        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit.Validate(Description, UnitDescription);
        if Sscc <> '' then
            HandlingUnit.Validate(SSCC, Sscc);
        HandlingUnit.Validate(Status, UnitStatus);
        ApplyFirstAvailableLocation(HandlingUnit);
        HandlingUnit.Insert(true);

        if ParentNo <> '' then begin
            HandlingUnit.Validate("Parent No.", ParentNo);
            HandlingUnit.Modify(true);
        end;
    end;

    local procedure ApplyFirstAvailableLocation(var HandlingUnit: Record "WHA Handling Unit")
    var
        Location: Record Location;
    begin
        Location.SetLoadFields(Code);
        Location.SetRange("Use As In-Transit", false);
        if not Location.FindFirst() then
            exit;

        HandlingUnit.Validate("Location Code", Location.Code);
    end;

    local procedure InsertSampleContents()
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("No.");
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetRange(Blocked, false);
        if not Item.FindSet() then
            exit;

        InsertLine('DEMO-HU-001', 10000, Item."No.", 12);
        if Item.Next() = 0 then
            exit;
        InsertLine('DEMO-HU-001', 20000, Item."No.", 6);
        if Item.Next() = 0 then
            exit;
        InsertLine('DEMO-HU-002', 10000, Item."No.", 24);
    end;

    local procedure InsertLine(UnitNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; Qty: Decimal)
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        if HandlingUnitLine.Get(UnitNo, LineNo) then
            exit;

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Line No." := LineNo;
        HandlingUnitLine.Validate("Item No.", ItemNo);
        HandlingUnitLine.Validate(Quantity, Qty);
        HandlingUnitLine.Insert(true);
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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Handling Unit Line");
    end;
}
