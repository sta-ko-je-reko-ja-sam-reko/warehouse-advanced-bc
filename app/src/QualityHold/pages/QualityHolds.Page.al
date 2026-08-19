namespace WarehouseAdvanced.QualityHold;

page 50551 "WHA Quality Holds"
{
    PageType = List;
    ApplicationArea = WHAQualityHold;
    UsageCategory = Lists;
    SourceTable = "WHA Quality Hold";
    Caption = 'Quality holds';
    CardPageId = "WHA Quality Hold Card";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Holds)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Handling Unit No."; Rec."Handling Unit No.")
                {
                }
                field(Reason; Rec.Reason)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field(Disposition; Rec.Disposition)
                {
                }
                field("Cascaded From Entry No."; Rec."Cascaded From Entry No.")
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                }
                field("Held By User ID"; Rec."Held By User ID")
                {
                }
                field("Held At"; Rec."Held At")
                {
                }
                field("Released By User ID"; Rec."Released By User ID")
                {
                }
                field("Released At"; Rec."Released At")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowOutstanding)
            {
                Caption = 'Show what is still on hold';
                ToolTip = 'Specifies the action that narrows the list to the goods that are still stopped, which is the list somebody has to work through.';
                Image = FilterLines;

                trigger OnAction()
                begin
                    Rec.SetRange(Status, Rec.Status::WHAOnHold);
                    CurrPage.Update(false);
                end;
            }
            action(ShowAll)
            {
                Caption = 'Show everything';
                ToolTip = 'Specifies the action that shows every hold ever placed, including the ones that have been lifted.';
                Image = ClearFilter;

                trigger OnAction()
                begin
                    Rec.SetRange(Status);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowOutstandingRef; ShowOutstanding)
                {
                }
                actionref(ShowAllRef; ShowAll)
                {
                }
            }
        }
    }
}
