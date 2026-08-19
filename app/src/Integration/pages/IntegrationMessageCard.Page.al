namespace WarehouseAdvanced.Integration;

page 50652 "WHA Integration Message Card"
{
    PageType = Card;
    ApplicationArea = WHAIntegration;
    UsageCategory = None;
    SourceTable = "WHA Integration Message";
    Caption = 'Integration message';
    InsertAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
                field("Correlation Id"; Rec."Correlation Id")
                {
                }
            }
            group(Handling)
            {
                Caption = 'Handling';

                field(Status; Rec.Status)
                {
                }
                field("Error Message"; Rec."Error Message")
                {
                    MultiLine = true;
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
                field("Record ID"; Format(Rec."Record ID"))
                {
                    Caption = 'Record ID';
                    ToolTip = 'Specifies the record the message created, changed, or was built from.';
                }
            }
            group(Body)
            {
                Caption = 'Body';

                field(PayloadText; PayloadText)
                {
                    Caption = 'Payload';
                    ToolTip = 'Specifies the message body exactly as it was received or built.';
                    MultiLine = true;
                    Editable = false;
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
                ToolTip = 'Specifies the action that applies this inbound message.';
                Image = Approve;

                trigger OnAction()
                begin
                    MessageMgt.Process(Rec);
                end;
            }
            action(AcknowledgeMessage)
            {
                Caption = 'Acknowledge';
                ToolTip = 'Specifies the action that records that the partner system has collected this outbound message.';
                Image = Confirm;

                trigger OnAction()
                begin
                    MessageMgt.Acknowledge(Rec);
                end;
            }
            action(CancelMessage)
            {
                Caption = 'Cancel';
                ToolTip = 'Specifies the action that drops this message without acting on it.';
                Image = Cancel;

                trigger OnAction()
                begin
                    MessageMgt.Cancel(Rec);
                end;
            }
        }
        area(Navigation)
        {
            action(ShowRecord)
            {
                Caption = 'Show record';
                ToolTip = 'Specifies the action that opens the record this message created, changed, or was built from.';
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
                actionref(ShowRecordRef; ShowRecord)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PayloadText := MessageMgt.GetPayload(Rec);
    end;

    var
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        PayloadText: Text;
}
