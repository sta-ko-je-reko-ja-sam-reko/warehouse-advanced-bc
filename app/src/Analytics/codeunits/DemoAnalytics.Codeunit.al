namespace WarehouseAdvanced.Analytics;

using System.IO;

codeunit 50704 "WHA Demo Analytics"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-KPI', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Analytics';

    /// <summary>
    /// Captures one set of figures for the company, over the period the setup asks for. Like slotting,
    /// this seeds nothing of its own: a KPI is a statement about work that was actually done, and a made
    /// up one would be a number nobody could check. On an empty company every figure is correctly zero.
    /// Idempotent - capturing the same period twice replaces the figures rather than adding a second set.
    /// Also builds this feature's RapidStart configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Analytics Setup";
        KPIFeatureSetup: Codeunit "WHA KPI Feature Setup";
        KpiMgt: Codeunit "WHA KPI Mgt.";
    begin
        KPIFeatureSetup.EnsureSetup(Setup);

        KpiMgt.Capture(Setup."Capture Location Code", 0D, 0D);

        CreateConfigPackage();
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
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA KPI Snapshot");
    end;
}
