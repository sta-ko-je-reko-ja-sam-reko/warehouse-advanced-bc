namespace WarehouseAdvanced.QualityHold;

using System.IO;
using WarehouseAdvanced.HandlingUnit;

codeunit 50554 "WHA Demo Quality Hold"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-QC', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Quality Hold';
        DamagedUnitTok: Label 'DEMO-HU-001', Locked = true;
        CheckedUnitTok: Label 'DEMO-HU-003', Locked = true;
        DamagedDescLbl: Label 'Shrink wrap torn, three cases crushed';
        CheckedDescLbl: Label 'Looked wet on arrival - checked and dry';

    /// <summary>
    /// Seeds sample quality holds against the handling unit sample data: a damaged pallet still waiting
    /// for somebody to decide, which drags the carton nested inside it into quarantine as well, and a cage
    /// that was held, checked and released back into stock. Idempotent — a unit that already has a hold on
    /// record is left alone. Also builds this feature's RapidStart configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Quality Hold Setup";
        QCFeatureSetup: Codeunit "WHA QC Feature Setup";
    begin
        QCFeatureSetup.EnsureSetup(Setup);

        CreateDamagedHold();
        CreateCheckedAndReleasedHold();

        CreateConfigPackage();
    end;

    local procedure CreateDamagedHold()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
    begin
        if not FreeUnit(HandlingUnit, CopyStr(DamagedUnitTok, 1, 20)) then
            exit;

        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, DamagedDescLbl);
    end;

    local procedure CreateCheckedAndReleasedHold()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Disposition: Enum "WHA Hold Disposition";
    begin
        if not FreeUnit(HandlingUnit, CopyStr(CheckedUnitTok, 1, 20)) then
            exit;

        QualityHoldMgt.Place(HandlingUnit, Reason::WHAInspection, CheckedDescLbl);
        if not QualityHoldMgt.ActiveHold(HandlingUnit."No.", QualityHold) then
            exit;

        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);
        QualityHoldMgt.Release(QualityHold);
    end;

    local procedure FreeUnit(var HandlingUnit: Record "WHA Handling Unit"; UnitNo: Code[20]): Boolean
    var
        QualityHold: Record "WHA Quality Hold";
    begin
        if not HandlingUnit.Get(UnitNo) then
            exit(false);
        if HandlingUnit.Status in [HandlingUnit.Status::WHAShipped, HandlingUnit.Status::WHAScrapped] then
            exit(false);

        QualityHold.SetCurrentKey("Handling Unit No.", Status);
        QualityHold.SetRange("Handling Unit No.", UnitNo);
        exit(QualityHold.IsEmpty());
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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Quality Hold");
    end;
}
