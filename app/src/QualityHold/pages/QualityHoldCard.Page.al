namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

page 50552 "WHA Quality Hold Card"
{
    PageType = Card;
    ApplicationArea = WHAQualityHold;
    UsageCategory = None;
    SourceTable = "WHA Quality Hold";
    Caption = 'Quality hold';
    InsertAllowed = false;
    DeleteAllowed = false;

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
                field("Handling Unit No."; Rec."Handling Unit No.")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Cascaded From Entry No."; Rec."Cascaded From Entry No.")
                {
                }
            }
            group(Why)
            {
                Caption = 'Why it was stopped';

                field(Reason; Rec.Reason)
                {
                }
                field(Description; Rec.Description)
                {
                    MultiLine = true;
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                }
            }
            group(Decision)
            {
                Caption = 'What happens to the goods';

                field(Disposition; Rec.Disposition)
                {
                }
                field(DispositionDescription; DispositionDescription)
                {
                    Caption = 'What that means';
                    ToolTip = 'Specifies what this decision does to the goods when the hold is released.';
                    Editable = false;
                    MultiLine = true;
                }
                field("Previous Unit Status"; Rec."Previous Unit Status")
                {
                }
            }
            group(Trail)
            {
                Caption = 'Who and when';

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
            action(ReleaseHold)
            {
                Caption = 'Release';
                ToolTip = 'Specifies the action that lifts the hold and carries out the decision, on this unit and on everything that was held with it.';
                Image = ReleaseDoc;

                trigger OnAction()
                var
                    QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
                begin
                    QualityHoldMgt.Release(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(HeldUnit)
            {
                Caption = 'Handling unit';
                ToolTip = 'Specifies the action that opens the handling unit this hold was placed on.';
                Image = Item;
                RunObject = page "WHA Handling Unit Card";
                RunPageLink = "No." = field("Handling Unit No.");
            }
            action(HeldWithThis)
            {
                Caption = 'Held with this one';
                ToolTip = 'Specifies the action that shows the holds placed on the units that were inside this one.';
                Image = List;
                RunObject = page "WHA Quality Holds";
                RunPageLink = "Cascaded From Entry No." = field("Entry No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ReleaseHoldRef; ReleaseHold)
                {
                }
                actionref(HeldUnitRef; HeldUnit)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescribeDisposition();
    end;

    var
        DispositionDescription: Text;

    local procedure DescribeDisposition()
    var
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
    begin
        DispositionDescription := QualityHoldMgt.DescribeDisposition(Rec);
    end;
}
