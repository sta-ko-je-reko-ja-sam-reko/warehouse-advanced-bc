namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.DirectedWork;

codeunit 50155 "WHA Wave Due Strategy" implements "WHA IWaveStrategy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The work due soonest at this location, whatever its priority.';

    /// <summary>
    /// Picks the work due soonest, ignoring priority. A warehouse that ships to a departure time cares
    /// more about what leaves at four o'clock than about what somebody marked urgent.
    /// </summary>
    /// <param name="Wave">The wave being filled.</param>
    /// <param name="WarehouseTask">The task record to filter and sort.</param>
    /// <returns>True when there is at least one candidate.</returns>
    procedure SelectCandidates(var Wave: Record "WHA Wave"; var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        StrategyFilters: Codeunit "WHA Wave Strategy Filters";
    begin
        StrategyFilters.ApplyCandidateFilters(Wave, WarehouseTask);
        WarehouseTask.SetCurrentKey("Due Date");
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
