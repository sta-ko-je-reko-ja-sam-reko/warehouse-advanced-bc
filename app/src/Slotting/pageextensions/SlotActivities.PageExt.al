namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

pageextension 50301 "WHA Slot Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Slotting Proposals Open"; Rec."WHA Slotting Proposals Open")
            {
                ApplicationArea = WHASlotting;
                DrillDownPageId = "WHA Slotting Proposals";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Slotting Proposals Open", Results, Rec.FieldNo("WHA Slotting Proposals Open"));
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
