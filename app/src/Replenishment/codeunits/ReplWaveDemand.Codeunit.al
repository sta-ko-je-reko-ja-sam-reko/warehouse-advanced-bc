namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.DirectedWork;

codeunit 50259 "WHA Repl. Wave Demand" implements "WHA IReplDemand"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Only the picks in the wave being planned for. This is what fills a pick face before a wave goes out rather than after it has stalled halfway through.';

    /// <summary>
    /// Counts only what one wave will take out of the bin. Asked with no wave, it counts nothing: the
    /// question "what will this wave need" has no answer when there is no wave, and answering it with
    /// every outstanding pick would quietly be a different question.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule whose bin is being weighed up.</param>
    /// <param name="WaveNo">The wave being planned for.</param>
    /// <returns>The quantity that wave will draw from the bin.</returns>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"; WaveNo: Code[20]): Decimal
    var
        WarehouseTask: Record "WHA Warehouse Task";
        DemandFilters: Codeunit "WHA Repl. Demand Filters";
    begin
        if WaveNo = '' then
            exit(0);

        DemandFilters.ApplyDemandFilters(ReplenishmentRule, WarehouseTask);
        WarehouseTask.SetRange("Wave No.", WaveNo);
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
