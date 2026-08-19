namespace WarehouseAdvanced.Counting;

using Microsoft.Inventory.Location;
using System.IO;
using WarehouseAdvanced.HandlingUnit;

codeunit 50504 "WHA Demo Count"
{
    Access = Public;

    var
        DemoLocationCode: Code[10];
        PackageCodeTok: Label 'WHA-COUNT', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Counting';
        BinSheetDescLbl: Label 'Aisle A - bins';
        UnitSheetDescLbl: Label 'Aisle B - pallets';
        BlindSheetDescLbl: Label 'Month end - not started yet';

    /// <summary>
    /// Seeds sample count sheets: one built from the bins at a location, one built from the handling units
    /// standing there and part-counted with a difference on it, and one blind sheet that has not been
    /// started. Idempotent — re-running creates nothing new. Also builds this feature's RapidStart
    /// configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Count Setup";
        CountFeatureSetup: Codeunit "WHA Count Feature Setup";
    begin
        CountFeatureSetup.EnsureSetup(Setup);

        DemoLocationCode := FirstLocationWithUnits();

        CreateBinSheet();
        CreateUnitSheet();
        CreateBlindSheet();

        CreateConfigPackage();
    end;

    local procedure CreateBinSheet()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Selection: Enum "WHA Count Selection";
    begin
        if not InsertSheet(CountSheet, 'DEMO-COUNT-001', BinSheetDescLbl, Selection::WHABinContent, false) then
            exit;
        if CountSheet."Location Code" = '' then
            exit;

        CountSheetLogic.Fill(CountSheet);
    end;

    local procedure CreateUnitSheet()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Selection: Enum "WHA Count Selection";
    begin
        if not InsertSheet(CountSheet, 'DEMO-COUNT-002', UnitSheetDescLbl, Selection::WHAHandlingUnits, false) then
            exit;
        if CountSheet."Location Code" = '' then
            exit;
        if CountSheetLogic.Fill(CountSheet) = 0 then
            exit;

        CountSheetLogic.Start(CountSheet);
        CountFirstLineShort(CountSheet);
    end;

    local procedure CreateBlindSheet()
    var
        CountSheet: Record "WHA Count Sheet";
        Selection: Enum "WHA Count Selection";
    begin
        if InsertSheet(CountSheet, 'DEMO-COUNT-003', BlindSheetDescLbl, Selection::WHABinContent, true) then;
    end;

    local procedure InsertSheet(var CountSheet: Record "WHA Count Sheet"; SheetNo: Code[20]; SheetDescription: Text[100]; SheetSelection: Enum "WHA Count Selection"; CountBlind: Boolean): Boolean
    begin
        if CountSheet.Get(SheetNo) then
            exit(false);

        CountSheet.Init();
        CountSheet."No." := SheetNo;
        CountSheet.Validate(Description, SheetDescription);
        CountSheet.Validate(Selection, SheetSelection);
        CountSheet.Validate(Blind, CountBlind);
        CountSheet.Validate("Due Date", WorkDate());
        if DemoLocationCode <> '' then
            CountSheet.Validate("Location Code", DemoLocationCode);
        CountSheet.Insert(true);
        exit(true);
    end;

    local procedure CountFirstLineShort(var CountSheet: Record "WHA Count Sheet")
    var
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        CountSheetLine.SetRange("Sheet No.", CountSheet."No.");
        if not CountSheetLine.FindFirst() then
            exit;

        if CountSheetLine."Expected Quantity" <= 0 then
            CountLineLogic.RecordCount(CountSheetLine, 0)
        else
            CountLineLogic.RecordCount(CountSheetLine, CountSheetLine."Expected Quantity" - 1);
    end;

    local procedure FirstLocationWithUnits(): Code[10]
    var
        HandlingUnit: Record "WHA Handling Unit";
        Location: Record Location;
    begin
        HandlingUnit.SetLoadFields("Location Code");
        HandlingUnit.SetFilter("Location Code", '<>%1', '');
        HandlingUnit.SetFilter(Status, '<>%1', HandlingUnit.Status::WHAShipped);
        if HandlingUnit.FindFirst() then
            exit(HandlingUnit."Location Code");

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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Count Sheet");
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Count Sheet Line");
    end;
}
