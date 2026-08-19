namespace WarehouseAdvanced.HandlingUnit;

page 50052 "WHA Handling Units"
{
    PageType = List;
    ApplicationArea = WHAHandlingUnits;
    UsageCategory = Lists;
    SourceTable = "WHA Handling Unit";
    Caption = 'Handling units';
    CardPageId = "WHA Handling Unit Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Units)
            {
                field("No."; Rec."No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(SSCC; Rec.SSCC)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                }
                field("Parent No."; Rec."Parent No.")
                {
                }
                field("Nested Unit Count"; Rec."Nested Unit Count")
                {
                }
                field(Status; Rec.Status)
                {
                }
            }
        }
    }
}
