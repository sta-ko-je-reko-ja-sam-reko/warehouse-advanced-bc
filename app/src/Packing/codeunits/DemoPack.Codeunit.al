namespace WarehouseAdvanced.Packing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.IO;

codeunit 50403 "WHA Demo Pack"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-PACK', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Packing';
        BenchOneDescLbl: Label 'Packing bench 1 - single orders';
        BenchTwoDescLbl: Label 'Packing bench 2 - multi-line orders';
        BenchSpareDescLbl: Label 'Packing bench 3 - out of use';

    /// <summary>
    /// Seeds sample packing benches and one worked example: a carton packed, checked and closed at the
    /// first bench. Idempotent — re-running creates nothing new.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Pack Setup";
        PackFeatureSetup: Codeunit "WHA Pack Feature Setup";
    begin
        PackFeatureSetup.EnsureSetup(Setup);

        InsertStation('DEMO-PACK-01', BenchOneDescLbl, false);
        InsertStation('DEMO-PACK-02', BenchTwoDescLbl, false);
        InsertStation('DEMO-PACK-03', BenchSpareDescLbl, true);

        SetDefaultStation('DEMO-PACK-01');
        CreateWorkedExample();

        CreateConfigPackage();
    end;

    local procedure InsertStation(StationCode: Code[20]; StationDescription: Text[100]; IsBlocked: Boolean)
    var
        PackStation: Record "WHA Pack Station";
    begin
        if PackStation.Get(StationCode) then
            exit;

        PackStation.Init();
        PackStation."Code" := StationCode;
        PackStation.Validate(Description, StationDescription);
        if FirstLocation() <> '' then
            PackStation.Validate("Location Code", FirstLocation());
        PackStation.Validate(Blocked, IsBlocked);
        PackStation.Insert(true);
    end;

    local procedure SetDefaultStation(StationCode: Code[20])
    var
        Setup: Record "WHA Pack Setup";
    begin
        if not Setup.Get() then
            exit;
        if Setup."Default Station Code" <> '' then
            exit;

        Setup.Validate("Default Station Code", StationCode);
        Setup.Modify(true);
    end;

    local procedure CreateWorkedExample()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
        ItemNo: Code[20];
    begin
        if ExampleExists() then
            exit;

        ItemNo := FirstItem();
        if ItemNo = '' then
            exit;

        PackLogic.Start(PackSession, 'DEMO-PACK-01');
        PackLogic.PackItem(PackSession, ItemNo, '', 3);
        PackLogic.Verify(PackSession);
        PackLogic.Close(PackSession);
    end;

    local procedure ExampleExists(): Boolean
    var
        PackSession: Record "WHA Pack Session";
    begin
        PackSession.SetLoadFields("Entry No.");
        PackSession.SetRange("Station Code", 'DEMO-PACK-01');
        exit(not PackSession.IsEmpty());
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

    local procedure FirstItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("No.");
        Item.SetRange(Type, Item.Type::Inventory);
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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Pack Station");
    end;
}
