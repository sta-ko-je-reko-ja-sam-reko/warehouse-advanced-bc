namespace WarehouseAdvanced.Integration;

page 50651 "WHA Integration Messages"
{
    PageType = List;
    ApplicationArea = WHAIntegration;
    UsageCategory = Lists;
    SourceTable = "WHA Integration Message";
    Caption = 'Integration messages';
    CardPageId = "WHA Integration Message Card";
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Messages)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field(Direction; Rec.Direction)
                {
                }
                field("Message Type"; Rec."Message Type")
                {
                }
                field("Partner System"; Rec."Partner System")
                {
                }
                field("External Id"; Rec."External Id")
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field("Error Message"; Rec."Error Message")
                {
                }
                field("Retry Count"; Rec."Retry Count")
                {
                }
                field("Received At"; Rec."Received At")
                {
                }
                field("Processed At"; Rec."Processed At")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessMessage)
            {
                Caption = 'Process';
                ToolTip = 'Specifies the action that applies the selected inbound message.';
                Image = Approve;

                trigger OnAction()
                begin
                    MessageMgt.Process(Rec);
                end;
            }
            action(AcknowledgeMessage)
            {
                Caption = 'Acknowledge';
                ToolTip = 'Specifies the action that records that the partner system has collected the selected outbound message.';
                Image = Confirm;

                trigger OnAction()
                begin
                    MessageMgt.Acknowledge(Rec);
                end;
            }
            action(CancelMessage)
            {
                Caption = 'Cancel';
                ToolTip = 'Specifies the action that drops the selected message without acting on it.';
                Image = Cancel;

                trigger OnAction()
                begin
                    MessageMgt.Cancel(Rec);
                end;
            }
            action(ProcessQueue)
            {
                Caption = 'Process all waiting';
                ToolTip = 'Specifies the action that applies every inbound message that is waiting, and tries failed ones again.';
                Image = Refresh;

                trigger OnAction()
                begin
                    MessageMgt.ProcessQueue();
                end;
            }
            action(CollectOutbound)
            {
                Caption = 'Fill the outbox';
                ToolTip = 'Specifies the action that adds an outbound message for everything the partner system has not been told about yet.';
                Image = Export;

                trigger OnAction()
                begin
                    MessageMgt.SweepOutbound();
                end;
            }
        }
        area(Navigation)
        {
            action(ShowRecord)
            {
                Caption = 'Show record';
                ToolTip = 'Specifies the action that opens the record the message created, changed, or was built from.';
                Image = Navigate;

                trigger OnAction()
                begin
                    MessageMgt.ShowRecord(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ProcessMessageRef; ProcessMessage)
                {
                }
                actionref(AcknowledgeMessageRef; AcknowledgeMessage)
                {
                }
                actionref(ProcessQueueRef; ProcessQueue)
                {
                }
                actionref(CollectOutboundRef; CollectOutbound)
                {
                }
                actionref(ShowRecordRef; ShowRecord)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    var
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        StatusStyle: Text;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::WHAFailed:
                StatusStyle := 'Unfavorable';
            Rec.Status::WHAProcessed:
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
