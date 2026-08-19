namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

pageextension 50401 "WHA Pack Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Cartons Being Packed"; Rec."WHA Cartons Being Packed")
            {
                ApplicationArea = WHAPacking;
                DrillDownPageId = "WHA Pack Sessions";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Cartons Being Packed", Results, Rec.FieldNo("WHA Cartons Being Packed"));
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
