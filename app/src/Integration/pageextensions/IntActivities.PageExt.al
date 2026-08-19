namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

pageextension 50651 "WHA Int Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Messages Waiting"; Rec."WHA Messages Waiting")
            {
                ApplicationArea = WHAIntegration;
                DrillDownPageId = "WHA Integration Messages";
            }
            field("WHA Messages Failed"; Rec."WHA Messages Failed")
            {
                ApplicationArea = WHAIntegration;
                DrillDownPageId = "WHA Integration Messages";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Messages Waiting", Results, Rec.FieldNo("WHA Messages Waiting"));
        SetCue(Rec."WHA Messages Failed", Results, Rec.FieldNo("WHA Messages Failed"));
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
