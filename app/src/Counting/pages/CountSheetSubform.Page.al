namespace WarehouseAdvanced.Counting;

page 50503 "WHA Count Sheet Subform"
{
    PageType = ListPart;
    ApplicationArea = WHACounting;
    SourceTable = "WHA Count Sheet Line";
    Caption = 'Lines';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Bin Code"; Rec."Bin Code")
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
                field(Description; Rec.Description)
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field("Lot No."; Rec."Lot No.")
                {
                }
                field("Serial No."; Rec."Serial No.")
                {
                }
                field("Expected Quantity"; Rec."Expected Quantity")
                {
                    Visible = ExpectedVisible;
                }
                field("Counted Quantity"; Rec."Counted Quantity")
                {
                }
                field(Counted; Rec.Counted)
                {
                }
                field(Variance; Rec.Variance)
                {
                    Visible = ExpectedVisible;
                }
                field("Out of Tolerance"; Rec."Out of Tolerance")
                {
                }
                field(Approved; Rec.Approved)
                {
                }
                field("Counted By User ID"; Rec."Counted By User ID")
                {
                }
                field("Counted At"; Rec."Counted At")
                {
                }
                field("Approved By User ID"; Rec."Approved By User ID")
                {
                }
                field("Posting Quantity"; Rec."Posting Quantity")
                {
                    Visible = ExpectedVisible;
                }
                field(Posted; Rec.Posted)
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApproveLine)
            {
                Caption = 'Approve difference';
                ToolTip = 'Specifies the action that accepts a difference that is bigger than the tolerance, so the sheet can be closed.';
                Image = Approve;

                trigger OnAction()
                var
                    CountLineLogic: Codeunit "WHA Count Line Logic";
                begin
                    CountLineLogic.Approve(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ExpectedVisible: Boolean;

    /// <summary>
    /// Decides whether the expected quantity and the difference are shown. A blind sheet hides them from
    /// the person counting, because a counter who can see the expected number tends to write it down.
    /// </summary>
    /// <param name="Show">Whether the expected quantity may be shown.</param>
    procedure SetExpectedVisible(Show: Boolean)
    begin
        ExpectedVisible := Show;
    end;
}
