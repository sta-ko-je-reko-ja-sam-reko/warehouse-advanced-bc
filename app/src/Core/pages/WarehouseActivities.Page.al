namespace WarehouseAdvanced.Core;

page 50003 "WHA Warehouse Activities"
{
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "WHA Activities Cue";
    Caption = 'Warehouse activities';

    layout
    {
        area(Content)
        {
            cuegroup(Warehouse)
            {
                ShowCaption = false;
            }
        }
    }

    trigger OnOpenPage()
    var
        TaskParameters: Dictionary of [Text, Text];
    begin
        Rec.InitCue();
        CurrPage.EnqueueBackgroundTask(CueTaskId, Codeunit::"WHA Activities Cue Calc", TaskParameters);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if TaskId <> CueTaskId then
            exit;

        CurrPage.Update(false);
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    var
        CueTaskId: Integer;
}
