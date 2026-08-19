namespace WarehouseAdvanced.WaveManagement;

using Microsoft.Inventory.Location;
using System.IO;
using WarehouseAdvanced.DirectedWork;

codeunit 50153 "WHA Demo Wave"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-WAVE', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Wave Management';
        MorningDescLbl: Label 'Morning pick round';
        AfternoonDescLbl: Label 'Afternoon departure';
        EmptyDescLbl: Label 'Evening round - nothing gathered yet';

    /// <summary>
    /// Seeds sample waves: one still being built, one filled and released to the floor, and one that was
    /// created and never used. Idempotent — re-running creates nothing new. Also builds this feature's
    /// RapidStart configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Wave Setup";
        WaveFeatureSetup: Codeunit "WHA Wave Feature Setup";
    begin
        WaveFeatureSetup.EnsureSetup(Setup);

        CreateOpenWave();
        CreateReleasedWave();
        CreateEmptyWave();

        CreateConfigPackage();
    end;

    local procedure CreateOpenWave()
    var
        Wave: Record "WHA Wave";
        WaveLogic: Codeunit "WHA Wave Logic";
        Strategy: Enum "WHA Wave Strategy";
    begin
        if not InsertWave(Wave, 'DEMO-WAVE-001', MorningDescLbl, Strategy::WHAMostUrgent, 5) then
            exit;

        if Wave."Location Code" = '' then
            exit;

        WaveLogic.Fill(Wave);
    end;

    local procedure CreateReleasedWave()
    var
        Wave: Record "WHA Wave";
        WaveLogic: Codeunit "WHA Wave Logic";
        Strategy: Enum "WHA Wave Strategy";
    begin
        if not InsertWave(Wave, 'DEMO-WAVE-002', AfternoonDescLbl, Strategy::WHADueFirst, 3) then
            exit;

        if Wave."Location Code" = '' then
            exit;
        if WaveLogic.Fill(Wave) = 0 then
            exit;

        WaveLogic.Release(Wave);
    end;

    local procedure CreateEmptyWave()
    var
        Wave: Record "WHA Wave";
        Strategy: Enum "WHA Wave Strategy";
    begin
        if InsertWave(Wave, 'DEMO-WAVE-003', EmptyDescLbl, Strategy::WHAMostUrgent, 0) then;
    end;

    local procedure InsertWave(var Wave: Record "WHA Wave"; WaveNo: Code[20]; WaveDescription: Text[100]; WaveStrategy: Enum "WHA Wave Strategy"; MaxTasks: Integer): Boolean
    begin
        if Wave.Get(WaveNo) then
            exit(false);

        Wave.Init();
        Wave."No." := WaveNo;
        Wave.Validate(Description, WaveDescription);
        Wave.Validate(Strategy, WaveStrategy);
        Wave.Validate("Max Tasks", MaxTasks);
        Wave.Validate("Location Code", FirstLocation());
        Wave.Insert(true);
        exit(true);
    end;

    local procedure FirstLocation(): Code[10]
    var
        Location: Record Location;
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetLoadFields("Location Code");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHAReleased);
        WarehouseTask.SetFilter("Location Code", '<>%1', '');
        if WarehouseTask.FindFirst() then
            exit(WarehouseTask."Location Code");

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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Wave");
    end;
}
