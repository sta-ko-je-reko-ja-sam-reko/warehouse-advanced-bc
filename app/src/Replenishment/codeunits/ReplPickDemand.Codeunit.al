namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.DirectedWork;

codeunit 50258 "WHA Repl. Pick Demand" implements "WHA IReplDemand"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Every pick still outstanding against the bin, whatever wave it belongs to. A pick face with a hundred pieces in it and ninety already promised is treated as having ten.';

    /// <summary>
    /// Counts everything already planned out of the bin: every pick that has not been finished or
    /// withdrawn, whatever wave it belongs to and whoever is holding it. Work part-finished counts only
    /// for what is left of it.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule whose bin is being weighed up.</param>
    /// <param name="WaveNo">Ignored. This way of counting does not care which wave the work is in.</param>
    /// <returns>The quantity already promised out of the bin.</returns>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"; WaveNo: Code[20]): Decimal
    var
        WarehouseTask: Record "WHA Warehouse Task";
        DemandFilters: Codeunit "WHA Repl. Demand Filters";
    begin
        DemandFilters.ApplyDemandFilters(ReplenishmentRule, WarehouseTask);
        exit(DemandFilters.SumOutstanding(WarehouseTask));
    end;

    /// <summary>
    /// Describes in one line what this way of counting demand looks at.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
