namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.DirectedWork;

codeunit 50154 "WHA Wave Default Strategy" implements "WHA IWaveStrategy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The most urgent work at this location first, then the work due soonest.';

    /// <summary>
    /// Picks the most urgent unwaved work at the wave's location. Urgency first and the due date only
    /// to break ties, which is the same order the queue itself hands work out in — so a wave built this
    /// way is the work that would have been done next anyway, gathered so it goes out together.
    /// </summary>
    /// <param name="Wave">The wave being filled.</param>
    /// <param name="WarehouseTask">The task record to filter and sort.</param>
    /// <returns>True when there is at least one candidate.</returns>
    procedure SelectCandidates(var Wave: Record "WHA Wave"; var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        StrategyFilters: Codeunit "WHA Wave Strategy Filters";
    begin
        StrategyFilters.ApplyCandidateFilters(Wave, WarehouseTask);
        WarehouseTask.SetCurrentKey(Status, "Location Code", Priority, "Due Date");
        exit(not WarehouseTask.IsEmpty());
    end;

    /// <summary>
    /// Describes in one line what this strategy picks.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
