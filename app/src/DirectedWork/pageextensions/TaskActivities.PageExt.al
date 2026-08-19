namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

pageextension 50202 "WHA Task Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Tasks Waiting"; Rec."WHA Tasks Waiting")
            {
                ApplicationArea = WHADirectedWork;
                DrillDownPageId = "WHA Warehouse Tasks";
            }
            field("WHA Tasks In Progress"; Rec."WHA Tasks In Progress")
            {
                ApplicationArea = WHADirectedWork;
                DrillDownPageId = "WHA Warehouse Tasks";
            }
            field("WHA Tasks Overdue"; Rec."WHA Tasks Overdue")
            {
                ApplicationArea = WHADirectedWork;
                DrillDownPageId = "WHA Warehouse Tasks";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Tasks Waiting", Results, Rec.FieldNo("WHA Tasks Waiting"));
        SetCue(Rec."WHA Tasks In Progress", Results, Rec.FieldNo("WHA Tasks In Progress"));
        SetCue(Rec."WHA Tasks Overdue", Results, Rec.FieldNo("WHA Tasks Overdue"));
    end;

    local procedure SetCue(var Target: Integer; Results: Dictionary of [Text, Text]; CueFieldNo: Integer)
    var
        Value: Integer;
    begin
        if not Results.ContainsKey(Format(CueFieldNo)) then
            exit;
        if not Evaluate(Value, Results.Get(Format(CueFieldNo))) then
            exit;

        Target := Value;
    end;
}
