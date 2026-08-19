namespace WarehouseAdvanced.HandlingUnit;

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
        area(Navigation)
        {
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
            }
        }
    }
}
