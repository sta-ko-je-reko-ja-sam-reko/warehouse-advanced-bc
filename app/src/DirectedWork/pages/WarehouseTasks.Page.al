namespace WarehouseAdvanced.DirectedWork;

page 50202 "WHA Warehouse Tasks"
{
    PageType = List;
    ApplicationArea = WHADirectedWork;
    UsageCategory = Lists;
    SourceTable = "WHA Warehouse Task";
    Caption = 'Warehouse tasks';
    CardPageId = "WHA Warehouse Task Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Tasks)
            {
                field("No."; Rec."No.")
                {
                }
                field("Task Type"; Rec."Task Type")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Priority; Rec.Priority)
                {
                }
                field("Due Date"; Rec."Due Date")
                {
                }
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
                field(Quantity; Rec.Quantity)
                {
                }
                field("Quantity Handled"; Rec."Quantity Handled")
                {
                }
                field("Short Reason"; Rec."Short Reason")
                {
                }
                field("Wave No."; Rec."Wave No.")
                {
                }
                field("Source Type"; Rec."Source Type")
                {
                }
                field("Source No."; Rec."Source No.")
                {
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                }
                field("Assigned To User ID"; Rec."Assigned To User ID")
                {
                }
                field(Status; Rec.Status)
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetNextTask)
            {
                Caption = 'Get next task';
                ToolTip = 'Specifies the action that hands you the work you should do next and assigns it to you.';
                Image = NextRecord;

                trigger OnAction()
                begin
                    ShowNextTask();
                end;
            }
            action(MyTasks)
            {
                Caption = 'My tasks';
                ToolTip = 'Specifies the action that shows only the tasks assigned to you.';
                Image = FilterLines;

                trigger OnAction()
                begin
                    FilterToCurrentUser();
                end;
            }
            action(AllTasks)
            {
                Caption = 'All tasks';
                ToolTip = 'Specifies the action that removes the filters set by the other actions.';
                Image = ClearFilter;

                trigger OnAction()
                begin
                    ClearUserFilter();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(GetNextTaskRef; GetNextTask)
                {
                }
                actionref(MyTasksRef; MyTasks)
                {
                }
                actionref(AllTasksRef; AllTasks)
                {
                }
            }
        }
    }

    var
        NoWorkMsg: Label 'There is no warehouse work waiting for you at the moment.';

    local procedure ShowNextTask()
    var
        NextTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if not TaskLogic.GetNextForUser(CurrentUser(), '', NextTask) then begin
            Message(NoWorkMsg);
            exit;
        end;

        Rec.Reset();
        if Rec.Get(NextTask."No.") then
            CurrPage.Update(false);
    end;

    local procedure FilterToCurrentUser()
    begin
        Rec.SetRange("Assigned To User ID", CurrentUser());
        CurrPage.Update(false);
    end;

    local procedure ClearUserFilter()
    begin
        Rec.SetRange("Assigned To User ID");
        CurrPage.Update(false);
    end;

    local procedure CurrentUser(): Code[50]
    begin
        exit(CopyStr(UserId(), 1, MaxStrLen(Rec."Assigned To User ID")));
    end;
}
