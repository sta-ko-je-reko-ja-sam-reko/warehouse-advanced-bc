namespace WarehouseAdvanced.HandlingUnit;

page 50055 "WHA Handling Unit Lines"
{
    PageType = ListPart;
    ApplicationArea = WHAHandlingUnits;
    SourceTable = "WHA Handling Unit Line";
    Caption = 'Contents';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Quantity; Rec.Quantity)
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
            }
        }
    }
}
