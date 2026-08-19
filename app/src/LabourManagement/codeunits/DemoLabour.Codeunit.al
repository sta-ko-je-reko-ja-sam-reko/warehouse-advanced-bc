namespace WarehouseAdvanced.LabourManagement;

using System.IO;
using WarehouseAdvanced.DirectedWork;

codeunit 50355 "WHA Demo Labour"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-LAB', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Labour Management';
        PutAwayDescLbl: Label 'Put-away - timed from the dock to the racking';
        PickDescLbl: Label 'Pick - one trip plus the handling per unit';
        MovementDescLbl: Label 'Movement - a whole unit, so the quantity does not matter';
        CountDescLbl: Label 'Count - measured per unit counted';
        BreakDescLbl: Label 'Morning break';

    /// <summary>
    /// Seeds sample labour standards covering both bases — three measured per job plus per unit, one
    /// measured per job only — turns whatever finished work exists into recorded time, and records one
    /// piece of indirect time so the two kinds can be told apart. Idempotent. Also builds this feature's
    /// RapidStart configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Labour Setup";
        LabFeatureSetup: Codeunit "WHA Lab. Feature Setup";
        LabourMgt: Codeunit "WHA Labour Mgt.";
    begin
        LabFeatureSetup.EnsureSetup(Setup);

        CreateStandards();
        CreateIndirectTime();

        LabourMgt.Generate('', 0D, 0D);

        CreateConfigPackage();
    end;

    local procedure CreateStandards()
    var
        TaskType: Enum "WHA Warehouse Task Type";
        Basis: Enum "WHA Labour Standard Basis";
    begin
        InsertStandard(TaskType::WHAPutAway, PutAwayDescLbl, Basis::WHAFixedPlusUnit, 4, 0.2);
        InsertStandard(TaskType::WHAPick, PickDescLbl, Basis::WHAFixedPlusUnit, 2, 0.35);
        InsertStandard(TaskType::WHAMovement, MovementDescLbl, Basis::WHAFixedOnly, 6, 0);
        InsertStandard(TaskType::WHACount, CountDescLbl, Basis::WHAFixedPlusUnit, 3, 0.15);
    end;

    local procedure InsertStandard(TaskType: Enum "WHA Warehouse Task Type"; StandardDescription: Text[100]; Basis: Enum "WHA Labour Standard Basis"; MinutesPerJob: Decimal; MinutesPerUnit: Decimal)
    var
        LabourStandard: Record "WHA Labour Standard";
    begin
        if LabourStandard.Get('', TaskType) then
            exit;

        LabourStandard.Init();
        LabourStandard."Location Code" := '';
        LabourStandard."Task Type" := TaskType;
        LabourStandard.Validate(Description, StandardDescription);
        LabourStandard.Validate(Basis, Basis);
        LabourStandard.Validate("Minutes Per Job", MinutesPerJob);
        LabourStandard.Validate("Minutes Per Unit", MinutesPerUnit);
        LabourStandard.Insert(true);
    end;

    local procedure CreateIndirectTime()
    var
        LabourEntry: Record "WHA Labour Entry";
        LabourMgt: Codeunit "WHA Labour Mgt.";
        Reason: Enum "WHA Indirect Reason";
    begin
        LabourEntry.SetRange("Entry Type", LabourEntry."Entry Type"::WHAIndirect);
        if not LabourEntry.IsEmpty() then
            exit;

        LabourMgt.RecordIndirect(CopyStr(UserId(), 1, 50), '', WorkDate(), Reason::WHABreak, 15, BreakDescLbl);
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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Labour Standard");
    end;
}
