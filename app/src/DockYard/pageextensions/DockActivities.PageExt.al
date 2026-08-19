namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

pageextension 50451 "WHA Dock Activities" extends "WHA Warehouse Activities"
{
    layout
    {
        addlast(Warehouse)
        {
            field("WHA Vehicles On Site"; Rec."WHA Vehicles On Site")
            {
                ApplicationArea = WHADockYard;
                DrillDownPageId = "WHA Dock Appointments";
            }
            field("WHA Vehicles Waiting"; Rec."WHA Vehicles Waiting")
            {
                ApplicationArea = WHADockYard;
                DrillDownPageId = "WHA Dock Appointments";
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        SetCue(Rec."WHA Vehicles On Site", Results, Rec.FieldNo("WHA Vehicles On Site"));
        SetCue(Rec."WHA Vehicles Waiting", Results, Rec.FieldNo("WHA Vehicles Waiting"));
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
