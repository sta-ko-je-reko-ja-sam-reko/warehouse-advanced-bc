namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.DirectedWork;

codeunit 50261 "WHA Repl. Demand Filters"
{
    Access = Public;

    /// <summary>
    /// Applies the filters every way of counting demand needs, so an implementation only has to decide
    /// which slice of it to look at. Work that is finished or withdrawn is never demand, and neither is
    /// work for a different item, a different location, or a bin this rule does not look after.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule whose bin is being weighed up.</param>
    /// <param name="WarehouseTask">The task record to filter. Existing filters are cleared first.</param>
    procedure ApplyDemandFilters(var ReplenishmentRule: Record "WHA Replenishment Rule"; var WarehouseTask: Record "WHA Warehouse Task")
    begin
        WarehouseTask.Reset();
        WarehouseTask.SetRange("Task Type", WarehouseTask."Task Type"::WHAPick);
        WarehouseTask.SetRange("Location Code", ReplenishmentRule."Location Code");
        WarehouseTask.SetRange("Item No.", ReplenishmentRule."Item No.");
        WarehouseTask.SetRange("Variant Code", ReplenishmentRule."Variant Code");
        WarehouseTask.SetFilter("From Bin Code", '%1|%2', ReplenishmentRule."Bin Code", '');
        WarehouseTask.SetFilter(Status, '<>%1&<>%2', WarehouseTask.Status::WHACompleted, WarehouseTask.Status::WHACancelled);
    end;

    /// <summary>
    /// Adds up what the filtered work will take out of the bin.
    /// </summary>
    /// <param name="WarehouseTask">The filtered task record to read.</param>
    /// <returns>The quantity the work is still expected to draw.</returns>
    procedure SumOutstanding(var WarehouseTask: Record "WHA Warehouse Task"): Decimal
    var
        Total: Decimal;
    begin
        WarehouseTask.SetLoadFields(Quantity, "Quantity Handled");
        if not WarehouseTask.FindSet() then
            exit(0);

        repeat
            Total += OutstandingOf(WarehouseTask);
        until WarehouseTask.Next() = 0;

        exit(Total);
    end;

    local procedure OutstandingOf(var WarehouseTask: Record "WHA Warehouse Task"): Decimal
    begin
        if WarehouseTask.Quantity <= WarehouseTask."Quantity Handled" then
            exit(0);
        exit(WarehouseTask.Quantity - WarehouseTask."Quantity Handled");
    end;
}
