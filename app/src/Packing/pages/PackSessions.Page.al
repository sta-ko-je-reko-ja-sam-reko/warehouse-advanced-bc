namespace WarehouseAdvanced.Packing;

page 50404 "WHA Pack Sessions"
{
    PageType = List;
    ApplicationArea = WHAPacking;
    UsageCategory = History;
    SourceTable = "WHA Pack Session";
    Caption = 'Packing sessions';
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Sessions)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Station Code"; Rec."Station Code")
                {
                }
                field("Handling Unit No."; Rec."Handling Unit No.")
                {
                }
                field("Line Count"; Rec."Line Count")
                {
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Packed By User ID"; Rec."Packed By User ID")
                {
                }
                field("Verified By User ID"; Rec."Verified By User ID")
                {
                }
                field("Started At"; Rec."Started At")
                {
                }
                field("Closed At"; Rec."Closed At")
                {
                }
            }
        }
    }
}
