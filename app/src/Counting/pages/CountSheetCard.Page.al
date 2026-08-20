namespace WarehouseAdvanced.Counting;

page 50502 "WHA Count Sheet Card"
{
    PageType = Document;
    ApplicationArea = WHACounting;
    UsageCategory = None;
    SourceTable = "WHA Count Sheet";
    Caption = 'Count sheet';

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
                field(Description; Rec.Description)
                {
                }
                field("Location Code"; Rec."Location Code")
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
                field("Posting Date"; Rec."Posting Date")
                {
                }
            }
            group(Building)
            {
                Caption = 'What is counted';

                field(Selection; Rec.Selection)
                {
                }
                field(SelectionDescription; SelectionDescription)
                {
                    Caption = 'What it gathers';
                    ToolTip = 'Specifies what this selection puts on the sheet when it is filled.';
                    Editable = false;
                    MultiLine = true;
                }
                field(Blind; Rec.Blind)
                {
                }
            }
            part(Lines; "WHA Count Sheet Subform")
            {
                Caption = 'Lines';
                SubPageLink = "Sheet No." = field("No.");
                UpdatePropagation = Both;
            }
            group(Progress)
            {
                Caption = 'Progress';

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
                field("Started At"; Rec."Started At")
                {
                }
                field("Counted At"; Rec."Counted At")
                {
                }
                field("Closed At"; Rec."Closed At")
                {
                }
            }
            group(Adjustment)
            {
                Caption = 'What was adjusted';

                field(Posted; Rec.Posted)
                {
                }
                field("Posting Document No."; Rec."Posting Document No.")
                {
                }
                field("Posted At"; Rec."Posted At")
                {
                }
            }
        }
    }

    actions
    {
        area(Reporting)
        {
            action(PrintSheet)
            {
                Caption = 'Print sheet';
                ToolTip = 'Print this count sheet to count against. A blind sheet is printed without the expected quantity.';
                ApplicationArea = WHACounting;
                Image = Print;

                trigger OnAction()
                var
                    CountSheet: Record "WHA Count Sheet";
                begin
                    CountSheet := Rec;
                    Report.Run(Report::"WHA Count Sheet Print", true, false, CountSheet);
                end;
            }
        }
        area(Processing)
        {
            action(FillSheet)
            {
                Caption = 'Fill';
                ToolTip = 'Specifies the action that puts a line on the sheet for everything its selection finds at the location.';
                Image = Refresh;

                trigger OnAction()
                begin
                    ApplyFill();
                end;
            }
            action(StartSheet)
            {
                Caption = 'Send out to be counted';
                ToolTip = 'Specifies the action that sends the sheet to the floor. From here what was expected is fixed, so the count is compared with what was believed when it was ordered.';
                Image = ReleaseDoc;

                trigger OnAction()
                begin
                    CountSheetLogic.Start(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CompleteSheet)
            {
                Caption = 'Mark as counted';
                ToolTip = 'Specifies the action that marks the sheet as counted once every line has been counted.';
                Image = Approve;

                trigger OnAction()
                begin
                    CountSheetLogic.Complete(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CloseSheet)
            {
                Caption = 'Close';
                ToolTip = 'Specifies the action that closes the sheet, once every difference beyond the tolerance has been approved, and hands its differences to the posting method set up for counting.';
                Image = Close;

                trigger OnAction()
                begin
                    CountSheetLogic.Close(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CancelSheet)
            {
                Caption = 'Cancel';
                ToolTip = 'Specifies the action that withdraws the sheet, keeping whatever was counted so far as a record.';
                Image = Cancel;

                trigger OnAction()
                begin
                    CountSheetLogic.Cancel(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(FillSheetRef; FillSheet)
                {
                }
                actionref(StartSheetRef; StartSheet)
                {
                }
                actionref(CompleteSheetRef; CompleteSheet)
                {
                }
                actionref(CloseSheetRef; CloseSheet)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescribeSelection();
        ApplyBlindness();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ApplyBlindness();
    end;

    var
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        SelectionDescription: Text;
        FilledMsg: Label '%1 line(s) put on the sheet.', Comment = '%1 = how many lines were added';

    local procedure ApplyFill()
    begin
        Message(FilledMsg, CountSheetLogic.Fill(Rec));
        CurrPage.Update(false);
    end;

    local procedure DescribeSelection()
    var
        CountSelection: Interface "WHA ICountSelection";
    begin
        CountSelection := Rec.Selection;
        SelectionDescription := CountSelection.Describe();
    end;

    local procedure ApplyBlindness()
    begin
        CurrPage.Lines.Page.SetExpectedVisible(not Rec.Blind or (Rec.Status in [Rec.Status::WHACounted, Rec.Status::WHAClosed]));
    end;
}
