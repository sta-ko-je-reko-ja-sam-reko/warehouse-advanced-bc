namespace WarehouseAdvanced.Analytics;

interface "WHA IKpiSnapshot"
{
    /// <summary>
    /// Stamps who took the figure and when. A snapshot without that is a number of unknown age, which is
    /// worse than no number.
    /// </summary>
    /// <param name="KpiSnapshot">The snapshot being inserted.</param>
    procedure Trigger_OnInsert(var KpiSnapshot: Record "WHA KPI Snapshot");
}
