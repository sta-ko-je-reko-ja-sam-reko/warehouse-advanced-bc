namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.Core;

codeunit 50710 "WHA KPI Scheduler"
{
    Access = Public;
    TableNo = "WHA KPI Snapshot";

    /// <summary>
    /// Keeps a snapshot of every measure for the setup's period. Point a job queue entry at this codeunit
    /// and Business Central decides when it happens; this feature never learns how to schedule, because
    /// the platform already knows and does it better than a setup page would.
    /// </summary>
    /// <param name="Rec">A snapshot record whose Location Code filter, if any, limits the capture to one site.</param>
    trigger OnRun()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAAnalytics);
        KpiMgt.Capture(CopyStr(Rec.GetFilter("Location Code"), 1, MaxStrLen(Rec."Location Code")), 0D, 0D);
    end;
}
