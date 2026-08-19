namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.DirectedWork;

codeunit 50156 "WHA Wave Strategy Filters"
{
    Access = Public;

    /// <summary>
    /// Applies the filters every wave strategy needs, so a strategy only has to decide the order. Work
    /// already in a wave, already in somebody's hands, or already finished is never a candidate — a
    /// strategy that forgot one of those would quietly steal work off the floor.
    /// </summary>
    /// <param name="Wave">The wave being filled.</param>
    /// <param name="WarehouseTask">The task record to filter. Existing filters are cleared first.</param>
    procedure ApplyCandidateFilters(var Wave: Record "WHA Wave"; var WarehouseTask: Record "WHA Warehouse Task")
    var
        Setup: Record "WHA Wave Setup";
        IncludeUnreleased: Boolean;
    begin
        Setup.SetLoadFields("Include Unreleased Work");
        if Setup.Get() then
            IncludeUnreleased := Setup."Include Unreleased Work";

        WarehouseTask.Reset();
        WarehouseTask.SetRange("Wave No.", '');
        WarehouseTask.SetRange("Location Code", Wave."Location Code");

        if IncludeUnreleased then
            WarehouseTask.SetFilter(Status, '%1|%2', WarehouseTask.Status::WHACreated, WarehouseTask.Status::WHAReleased)
        else
            WarehouseTask.SetRange(Status, WarehouseTask.Status::WHAReleased);
    end;
}
