namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

pageextension 50151 "WHA Wave Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Waves Open"; Rec."WHA Waves Open")
            {
                ApplicationArea = WHAWaveManagement;
                DrillDownPageId = "WHA Waves";
            }
            field("WHA Waves On Floor"; Rec."WHA Waves On Floor")
            {
                ApplicationArea = WHAWaveManagement;
                DrillDownPageId = "WHA Waves";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Waves Open", Results, Rec.FieldNo("WHA Waves Open"));
        SetCue(Rec."WHA Waves On Floor", Results, Rec.FieldNo("WHA Waves On Floor"));
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
