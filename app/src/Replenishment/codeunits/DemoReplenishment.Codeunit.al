namespace WarehouseAdvanced.Replenishment;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using System.IO;

codeunit 50253 "WHA Demo Replenishment"
{
    Access = Public;

    var
        DemoLocationCode: Code[10];
        DemoItemNo: Code[20];
        DemoPickBinCode: Code[20];
        DemoSecondBinCode: Code[20];
        DemoBulkBinCode: Code[20];
        PackageCodeTok: Label 'WHA-REPL', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Replenishment';
        PickFaceDescLbl: Label 'Keep the pick face full';
        UnitBinDescLbl: Label 'Pick face counted from the pallets standing in it';
        BlockedDescLbl: Label 'Seasonal line - not replenished out of season';

    /// <summary>
    /// Seeds sample replenishment rules: one measured from bin content and topped up from a bulk bin, one
    /// measured from the handling units standing in the bin, and one that is blocked. Idempotent —
    /// re-running creates nothing new. Also builds this feature's RapidStart configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Repl. Setup";
        ReplFeatureSetup: Codeunit "WHA Repl. Feature Setup";
    begin
        ReplFeatureSetup.EnsureSetup(Setup);

        ResolveContext();

        CreatePickFaceRule();
        CreateHandlingUnitRule();
        CreateBlockedRule();

        CreateConfigPackage();
    end;

    local procedure ResolveContext()
    begin
        ResolveLocationWithBins();
        DemoItemNo := FirstItem();
    end;

    local procedure CreatePickFaceRule()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        Method: Enum "WHA Repl. Method";
    begin
        if not PrepareRule(ReplenishmentRule, DemoPickBinCode, PickFaceDescLbl) then
            exit;

        ReplenishmentRule.Validate(Method, Method::WHABinContent);
        ReplenishmentRule.Validate("Minimum Quantity", 10);
        ReplenishmentRule.Validate("Maximum Quantity", 50);
        ReplenishmentRule.Validate(Priority, 20);
        if DemoBulkBinCode <> '' then
            ReplenishmentRule.Validate("Source Bin Code", DemoBulkBinCode);
        ReplenishmentRule.Insert(true);
    end;

    local procedure CreateHandlingUnitRule()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        Method: Enum "WHA Repl. Method";
    begin
        if not PrepareRule(ReplenishmentRule, DemoSecondBinCode, UnitBinDescLbl) then
            exit;

        ReplenishmentRule.Validate(Method, Method::WHAHandlingUnits);
        ReplenishmentRule.Validate("Minimum Quantity", 5);
        ReplenishmentRule.Validate("Maximum Quantity", 20);
        ReplenishmentRule.Validate(Priority, 40);
        ReplenishmentRule.Insert(true);
    end;

    local procedure CreateBlockedRule()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
    begin
        if not PrepareRule(ReplenishmentRule, DemoBulkBinCode, BlockedDescLbl) then
            exit;

        ReplenishmentRule.Validate("Minimum Quantity", 2);
        ReplenishmentRule.Validate("Maximum Quantity", 8);
        ReplenishmentRule.Validate(Blocked, true);
        ReplenishmentRule.Insert(true);
    end;

    local procedure PrepareRule(var ReplenishmentRule: Record "WHA Replenishment Rule"; BinCode: Code[20]; RuleDescription: Text[100]): Boolean
    begin
        if (DemoLocationCode = '') or (DemoItemNo = '') or (BinCode = '') then
            exit(false);
        if ReplenishmentRule.Get(DemoLocationCode, DemoItemNo, '', BinCode) then
            exit(false);

        ReplenishmentRule.Init();
        ReplenishmentRule."Location Code" := DemoLocationCode;
        ReplenishmentRule.Validate("Item No.", DemoItemNo);
        ReplenishmentRule."Bin Code" := BinCode;
        ReplenishmentRule.Validate(Description, RuleDescription);
        exit(true);
    end;

    local procedure ResolveLocationWithBins()
    var
        Location: Record Location;
    begin
        DemoLocationCode := '';
        DemoPickBinCode := '';
        DemoSecondBinCode := '';
        DemoBulkBinCode := '';

        Location.SetLoadFields(Code);
        Location.SetRange("Use As In-Transit", false);
        if not Location.FindSet() then
            exit;

        repeat
            if TakeBins(Location.Code) then begin
                DemoLocationCode := Location.Code;
                exit;
            end;
        until Location.Next() = 0;
    end;

    local procedure TakeBins(LocationCode: Code[10]): Boolean
    var
        Bin: Record Bin;
    begin
        Bin.SetLoadFields(Code);
        Bin.SetRange("Location Code", LocationCode);
        if not Bin.FindSet() then
            exit(false);

        DemoPickBinCode := Bin.Code;
        if Bin.Next() <> 0 then
            DemoSecondBinCode := Bin.Code;
        if Bin.Next() <> 0 then
            DemoBulkBinCode := Bin.Code;
        exit(true);
    end;

    local procedure FirstItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("No.");
        Item.SetRange(Blocked, false);
        if not Item.FindFirst() then
            exit('');
        exit(Item."No.");
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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Replenishment Rule");
    end;
}
