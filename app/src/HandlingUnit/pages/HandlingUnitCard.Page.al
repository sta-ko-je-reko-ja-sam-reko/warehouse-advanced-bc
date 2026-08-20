namespace WarehouseAdvanced.HandlingUnit;

using WarehouseAdvanced.Labelling;
using WarehouseAdvanced.QualityHold;

page 50051 "WHA Handling Unit Card"
{
    PageType = Card;
    ApplicationArea = WHAHandlingUnits;
    UsageCategory = None;
    SourceTable = "WHA Handling Unit";
    Caption = 'Handling unit';

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
                field(SSCC; Rec.SSCC)
                {
                }
                field(Status; Rec.Status)
                {
                }
            }
            group(Placement)
            {
                Caption = 'Placement';

                field("Location Code"; Rec."Location Code")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                }
            }
            part(Contents; "WHA Handling Unit Lines")
            {
                Caption = 'Contents';
                SubPageLink = "Handling Unit No." = field("No.");
                UpdatePropagation = Both;
            }
            group(Totals)
            {
                Caption = 'Totals';

                field("Total Quantity"; Rec."Total Quantity")
                {
                }
            }
            group(Nesting)
            {
                Caption = 'Nesting';

                field("Parent No."; Rec."Parent No.")
                {
                }
                field("Nested Unit Count"; Rec."Nested Unit Count")
                {
                }
            }
        }
    }

    actions
    {
        area(Reporting)
        {
            action(PrintContents)
            {
                Caption = 'Print contents';
                ToolTip = 'Print what is on this handling unit, as a contents list to travel with the goods.';
                ApplicationArea = WHAHandlingUnits;
                Image = Print;

                trigger OnAction()
                var
                    HandlingUnit: Record "WHA Handling Unit";
                begin
                    HandlingUnit := Rec;
                    Report.Run(Report::"WHA Handling Unit Contents", true, false, HandlingUnit);
                end;
            }
        }
        area(Navigation)
        {
            action(AssignLabel)
            {
                Caption = 'Assign label code';
                ToolTip = 'Specifies the action that gives this unit the code that goes on its label, in the format the labelling setup names.';
                Image = BarCode;
                ApplicationArea = WHALabelling;
                AccessByPermission = tabledata "WHA Label Setup" = R;

                trigger OnAction()
                var
                    LabelMgt: Codeunit "WHA Label Mgt.";
                begin
                    LabelMgt.AssignTo(Rec);
                end;
            }
            action(PutOnHold)
            {
                Caption = 'Put on hold';
                ToolTip = 'Specifies the action that stops this unit from being used, and everything nested inside it, until somebody decides what to do with the goods.';
                Image = Cancel;
                ApplicationArea = WHAQualityHold;
                AccessByPermission = tabledata "WHA Quality Hold" = I;

                trigger OnAction()
                begin
                    PlaceHold();
                end;
            }
            action(UnitHolds)
            {
                Caption = 'Quality holds';
                ToolTip = 'Specifies the action that shows every hold ever placed on this unit, whether or not it is still on.';
                Image = List;
                ApplicationArea = WHAQualityHold;
                AccessByPermission = tabledata "WHA Quality Hold" = R;
                RunObject = page "WHA Quality Holds";
                RunPageLink = "Handling Unit No." = field("No.");
            }
            action(NestedUnits)
            {
                Caption = 'Nested units';
                ToolTip = 'Specifies the action that shows the handling units placed inside this one.';
                Image = Hierarchy;
                RunObject = page "WHA Handling Units";
                RunPageLink = "Parent No." = field("No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(NestedUnitsRef; NestedUnits)
                {
                }
                actionref(AssignLabelRef; AssignLabel)
                {
                }
                actionref(PutOnHoldRef; PutOnHold)
                {
                }
            }
        }
    }

    var
        HeldMsg: Label 'Handling unit %1 is on hold under hold %2. Say what happens to the goods, then release it.', Comment = '%1 = the handling unit number, %2 = the entry number of the hold that was placed';

    local procedure PlaceHold()
    var
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        EntryNo: Integer;
    begin
        EntryNo := QualityHoldMgt.Place(Rec, QualityHoldMgt.DefaultReason(), '');
        CurrPage.Update(false);
        Message(HeldMsg, Rec."No.", EntryNo);
    end;
}
