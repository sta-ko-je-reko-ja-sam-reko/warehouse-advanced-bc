namespace WarehouseAdvanced.Slotting;

page 50303 "WHA API Item Velocity"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'slotting';
    APIVersion = 'v1.0';
    EntityName = 'itemVelocity';
    EntitySetName = 'itemVelocities';
    EntityCaption = 'Item velocity';
    EntitySetCaption = 'Item velocities';
    SourceTable = "WHA Item Velocity";
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item number';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant code';
                }
                field(movements; Rec.Movements)
                {
                    Caption = 'Movements';
                }
                field(quantityMoved; Rec."Quantity Moved")
                {
                    Caption = 'Quantity moved';
                }
                field(rankValue; Rec."Rank Value")
                {
                    Caption = 'Rank value';
                }
                field(velocityClass; Rec.Class)
                {
                    Caption = 'Class';
                }
                field(mainBinCode; Rec."Main Bin Code")
                {
                    Caption = 'Main bin code';
                }
                field(mainBinRanking; Rec."Main Bin Ranking")
                {
                    Caption = 'Main bin ranking';
                }
                field(fromDate; Rec."From Date")
                {
                    Caption = 'From date';
                }
                field(toDate; Rec."To Date")
                {
                    Caption = 'To date';
                }
                field(calculatedDateTime; Rec."Calculated At")
                {
                    Caption = 'Calculated date time';
                }
            }
        }
    }
}
