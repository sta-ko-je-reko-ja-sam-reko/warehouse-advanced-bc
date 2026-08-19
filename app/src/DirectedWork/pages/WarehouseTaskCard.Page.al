namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.HandlingUnit;

page 50201 "WHA Warehouse Task Card"
{
    PageType = Card;
    ApplicationArea = WHADirectedWork;
    UsageCategory = None;
    SourceTable = "WHA Warehouse Task";
    Caption = 'Warehouse task';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                }
                field("Task Type"; Rec."Task Type")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Status; Rec.Status)
                {
                }
            }
            group(Work)
            {
                Caption = 'Work';

                field("Location Code"; Rec."Location Code")
                {
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                }
                field("Handling Unit No."; Rec."Handling Unit No.")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                }
                field(Quantity; Rec.Quantity)
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field("Quantity Handled"; Rec."Quantity Handled")
                {
                }
                field("Short Reason"; Rec."Short Reason")
                {
                }
            }
            group(Queue)
            {
                Caption = 'Queue';

                field(Priority; Rec.Priority)
                {
                }
                field("Due Date"; Rec."Due Date")
                {
                }
                field("Wave No."; Rec."Wave No.")
                {
                }
                field("Assigned To User ID"; Rec."Assigned To User ID")
                {
                }
                field("Assigned At"; Rec."Assigned At")
                {
                }
                field("Started At"; Rec."Started At")
                {
                }
                field("Completed At"; Rec."Completed At")
                {
                }
            }
            group(Origin)
            {
                Caption = 'Where the work came from';

                field("Source Type"; Rec."Source Type")
                {
                }
                field(OriginDescription; OriginDescription)
                {
                    Caption = 'Document';
                    ToolTip = 'Specifies the document this job was raised from, named in full.';
                    Editable = false;
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                }
                field(SourceStillOpen; SourceStillOpen)
                {
                    Caption = 'Still wanted';
                    ToolTip = 'Specifies whether the line this job came from still has something outstanding on it. A job whose source has been received or shipped some other way is work nobody needs doing.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReleaseTask)
            {
                Caption = 'Release';
                ToolTip = 'Specifies the action that makes the task available to the floor.';
                Image = ReleaseDoc;

                trigger OnAction()
                begin
                    TaskLogic.Release(Rec);
                end;
            }
            action(AssignToMe)
            {
                Caption = 'Assign to me';
                ToolTip = 'Specifies the action that takes the task for yourself.';
                Image = UserSetup;

                trigger OnAction()
                begin
                    TaskLogic.Assign(Rec, CopyStr(UserId(), 1, MaxStrLen(Rec."Assigned To User ID")));
                end;
            }
            action(StartTask)
            {
                Caption = 'Start';
                ToolTip = 'Specifies the action that records that you have started working the task.';
                Image = Start;

                trigger OnAction()
                begin
                    TaskLogic.Start(Rec);
                end;
            }
            action(CompleteTask)
            {
                Caption = 'Complete';
                ToolTip = 'Specifies the action that records the work as done and moves the handling unit to the destination bin.';
                Image = Approve;

                trigger OnAction()
                begin
                    TaskLogic.Complete(Rec);
                end;
            }
            action(CancelTask)
            {
                Caption = 'Cancel';
                ToolTip = 'Specifies the action that withdraws the task without deleting it.';
                Image = Cancel;

                trigger OnAction()
                begin
                    TaskLogic.Cancel(Rec);
                end;
            }
        }
        area(Navigation)
        {
            action(SourceDocument)
            {
                Caption = 'Source document';
                ToolTip = 'Specifies the action that opens the warehouse document this job was raised from.';
                Image = Document;
                Enabled = HasSource;

                trigger OnAction()
                begin
                    OpenSource();
                end;
            }
            action(HandlingUnit)
            {
                Caption = 'Handling unit';
                ToolTip = 'Specifies the action that opens the handling unit the task moves.';
                Image = Hierarchy;
                RunObject = page "WHA Handling Units";
                RunPageLink = "No." = field("Handling Unit No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ReleaseTaskRef; ReleaseTask)
                {
                }
                actionref(AssignToMeRef; AssignToMe)
                {
                }
                actionref(StartTaskRef; StartTask)
                {
                }
                actionref(CompleteTaskRef; CompleteTask)
                {
                }
                actionref(CancelTaskRef; CancelTask)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescribeOrigin();
    end;

    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        OriginDescription: Text;
        SourceStillOpen: Boolean;
        HasSource: Boolean;
        NoSourceMsg: Label 'This job was put on the queue by hand, so there is no document behind it to open.';
        SourceGoneMsg: Label 'The document this job was raised from no longer exists.';

    local procedure DescribeOrigin()
    begin
        OriginDescription := TaskSourceMgt.DescribeLink(Rec);
        SourceStillOpen := TaskSourceMgt.SourceIsOpen(Rec);
        HasSource := OriginDescription <> '';
    end;

    local procedure OpenSource()
    begin
        if not HasSource then begin
            Message(NoSourceMsg);
            exit;
        end;
        if not TaskSourceMgt.ShowSource(Rec) then
            Message(SourceGoneMsg);
    end;
}
