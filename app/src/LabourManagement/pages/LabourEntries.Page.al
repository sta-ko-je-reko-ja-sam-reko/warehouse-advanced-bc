namespace WarehouseAdvanced.LabourManagement;

page 50352 "WHA Labour Entries"
{
    PageType = List;
    ApplicationArea = WHALabourManagement;
    UsageCategory = Lists;
    SourceTable = "WHA Labour Entry";
    Caption = 'Recorded time';
    DeleteAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Posting Date"; Rec."Posting Date")
                {
                }
                field("Entry Type"; Rec."Entry Type")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Task No."; Rec."Task No.")
                {
                }
                field("Task Type"; Rec."Task Type")
                {
                }
                field("Indirect Reason"; Rec."Indirect Reason")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Quantity Handled"; Rec."Quantity Handled")
                {
                }
                field("Actual Minutes"; Rec."Actual Minutes")
                {
                }
                field("Expected Minutes"; Rec."Expected Minutes")
                {
                }
                field("Performance Percent"; Rec."Performance Percent")
                {
                }
                field("Measured Against Standard"; Rec."Measured Against Standard")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateEntries)
            {
                Caption = 'Take time from finished work';
                ToolTip = 'Specifies the action that turns finished warehouse jobs into recorded time. Work that already has time recorded against it is left alone, so this is safe to run as often as you like.';
                Image = Timesheet;

                trigger OnAction()
                begin
                    ApplyGenerate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(GenerateEntriesRef; GenerateEntries)
                {
                }
            }
        }
    }

    var
        GeneratedMsg: Label '%1 piece(s) of time taken from finished work.', Comment = '%1 = how many labour entries were created';

    local procedure ApplyGenerate()
    var
        LabourMgt: Codeunit "WHA Labour Mgt.";
    begin
        Message(GeneratedMsg, LabourMgt.Generate('', 0D, 0D));
        CurrPage.Update(false);
    end;
}
