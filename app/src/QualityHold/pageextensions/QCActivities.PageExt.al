namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;

pageextension 50551 "WHA QC Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Goods On Hold"; Rec."WHA Goods On Hold")
            {
                ApplicationArea = WHAQualityHold;
                DrillDownPageId = "WHA Quality Holds";
            }
            field("WHA Holds To Decide"; Rec."WHA Holds To Decide")
            {
                ApplicationArea = WHAQualityHold;
                DrillDownPageId = "WHA Quality Holds";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Goods On Hold", Results, Rec.FieldNo("WHA Goods On Hold"));
        SetCue(Rec."WHA Holds To Decide", Results, Rec.FieldNo("WHA Holds To Decide"));
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
