namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

codeunit 50208 "WHA Task Activity Cues" implements "WHA IActivityCues"
{
    Access = Public;

    /// <summary>
    /// Counts the three things a warehouse manager looks at first: work nobody has picked up, work
    /// somebody is holding, and work that is already late.
    /// </summary>
    /// <param name="Results">The result buffer, keyed by cue field number.</param>
    procedure AddCounts(var Results: Dictionary of [Text, Text])
    var
        ActivitiesCue: Record "WHA Activities Cue";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHADirectedWork) then
            exit;

        Results.Add(Format(ActivitiesCue.FieldNo("WHA Tasks Waiting")), Format(CountWaiting()));
        Results.Add(Format(ActivitiesCue.FieldNo("WHA Tasks In Progress")), Format(CountInProgress()));
        Results.Add(Format(ActivitiesCue.FieldNo("WHA Tasks Overdue")), Format(CountOverdue()));
    end;

    local procedure CountWaiting(): Integer
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetCurrentKey(Status, "Location Code", Priority, "Due Date");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHAReleased);
        exit(WarehouseTask.Count());
    end;

    local procedure CountInProgress(): Integer
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetCurrentKey(Status, "Location Code", Priority, "Due Date");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHAInProgress);
        exit(WarehouseTask.Count());
    end;

    local procedure CountOverdue(): Integer
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetCurrentKey("Due Date", Priority);
        WarehouseTask.SetFilter("Due Date", '<%1&<>%2', WorkDate(), 0D);
        WarehouseTask.SetFilter(Status, '<>%1&<>%2', WarehouseTask.Status::WHACompleted, WarehouseTask.Status::WHACancelled);
        exit(WarehouseTask.Count());
    end;
}
