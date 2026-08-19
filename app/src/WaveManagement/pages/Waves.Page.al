namespace WarehouseAdvanced.WaveManagement;

page 50151 "WHA Waves"
{
    PageType = List;
    ApplicationArea = WHAWaveManagement;
    UsageCategory = Lists;
    SourceTable = "WHA Wave";
    Caption = 'Waves';
    CardPageId = "WHA Wave Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Waves)
            {
                field("No."; Rec."No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field(Strategy; Rec.Strategy)
                {
                }
                field("Task Count"; Rec."Task Count")
                {
                }
                field("Completed Task Count"; Rec."Completed Task Count")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Released At"; Rec."Released At")
                {
                }
                field("Completed At"; Rec."Completed At")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CloseFinished)
            {
                Caption = 'Close finished waves';
                ToolTip = 'Specifies the action that closes every released wave whose work is finished. Nothing closes a wave by itself, so run this on a schedule or when you want the list to tell the truth.';
                Image = Approve;

                trigger OnAction()
                begin
                    CloseFinishedWaves();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CloseFinishedRef; CloseFinished)
                {
                }
            }
        }
    }

    var
        ClosedMsg: Label '%1 wave(s) closed.', Comment = '%1 = how many waves were closed';

    local procedure CloseFinishedWaves()
    var
        Wave: Record "WHA Wave";
        WaveLogic: Codeunit "WHA Wave Logic";
        Closed: Integer;
    begin
        Wave.SetRange(Status, Wave.Status::WHAReleased);
        if Wave.FindSet() then
            repeat
                if WaveLogic.CompleteIfFinished(Wave) then
                    Closed += 1;
            until Wave.Next() = 0;

        Message(ClosedMsg, Closed);
        CurrPage.Update(false);
    end;
}
