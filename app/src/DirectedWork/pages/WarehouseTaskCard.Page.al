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

    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
}
