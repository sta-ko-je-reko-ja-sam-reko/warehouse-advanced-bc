namespace WarehouseAdvanced.Counting;

page 50501 "WHA Count Sheets"
{
    PageType = List;
    ApplicationArea = WHACounting;
    UsageCategory = Lists;
    SourceTable = "WHA Count Sheet";
    Caption = 'Count sheets';
    CardPageId = "WHA Count Sheet Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Sheets)
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
                field(Selection; Rec.Selection)
                {
                }
                field(Blind; Rec.Blind)
                {
                }
                field("Line Count"; Rec."Line Count")
                {
                }
                field("Counted Line Count"; Rec."Counted Line Count")
                {
                }
                field("Variance Line Count"; Rec."Variance Line Count")
                {
                }
                field("Unapproved Variance Count"; Rec."Unapproved Variance Count")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Due Date"; Rec."Due Date")
                {
                }
                field("Assigned To User ID"; Rec."Assigned To User ID")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CompleteCounted)
            {
                Caption = 'Mark fully counted sheets';
                ToolTip = 'Specifies the action that marks every sheet whose lines have all been counted as counted. Nothing does this by itself, so run it when you want the list to tell the truth.';
                Image = Approve;

                trigger OnAction()
                begin
                    MarkCountedSheets();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CompleteCountedRef; CompleteCounted)
                {
                }
            }
        }
    }

    var
        MarkedMsg: Label '%1 sheet(s) marked as counted.', Comment = '%1 = how many count sheets were marked';

    local procedure MarkCountedSheets()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Marked: Integer;
    begin
        CountSheet.SetRange(Status, CountSheet.Status::WHACounting);
        if CountSheet.FindSet() then
            repeat
                if CountSheetLogic.CompleteIfCounted(CountSheet) then
                    Marked += 1;
            until CountSheet.Next() = 0;

        Message(MarkedMsg, Marked);
        CurrPage.Update(false);
    end;
}
