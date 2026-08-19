namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

pageextension 50251 "WHA Repl Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Repl. Rules Blocked"; Rec."WHA Repl. Rules Blocked")
            {
                ApplicationArea = WHAReplenishment;
                DrillDownPageId = "WHA Replenishment Rules";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Repl. Rules Blocked", Results, Rec.FieldNo("WHA Repl. Rules Blocked"));
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
