namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

pageextension 50501 "WHA Count Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Count Sheets Out"; Rec."WHA Count Sheets Out")
            {
                ApplicationArea = WHACounting;
                DrillDownPageId = "WHA Count Sheets";
            }
            field("WHA Counts To Approve"; Rec."WHA Counts To Approve")
            {
                ApplicationArea = WHACounting;
                DrillDownPageId = "WHA Count Sheets";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Count Sheets Out", Results, Rec.FieldNo("WHA Count Sheets Out"));
        SetCue(Rec."WHA Counts To Approve", Results, Rec.FieldNo("WHA Counts To Approve"));
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
