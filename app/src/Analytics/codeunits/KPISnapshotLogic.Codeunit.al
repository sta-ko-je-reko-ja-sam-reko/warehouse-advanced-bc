namespace WarehouseAdvanced.Analytics;

codeunit 50701 "WHA KPI Snapshot Logic" implements "WHA IKpiSnapshot"
{
    Access = Public;

    /// <summary>
    /// Stamps who took the figure and when.
    /// </summary>
    /// <param name="KpiSnapshot">The snapshot being inserted.</param>
    procedure Trigger_OnInsert(var KpiSnapshot: Record "WHA KPI Snapshot")
    begin
        KpiSnapshot."Captured At" := CurrentDateTime;
        KpiSnapshot."Captured By User ID" := CopyStr(UserId(), 1, MaxStrLen(KpiSnapshot."Captured By User ID"));
    end;
}
