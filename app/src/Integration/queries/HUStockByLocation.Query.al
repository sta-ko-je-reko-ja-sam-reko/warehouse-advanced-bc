namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.HandlingUnit;

query 50672 "WHA HU Stock By Location"
{
    QueryType = Normal;
    Caption = 'Handling unit stock by location';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(HandlingUnit; "WHA Handling Unit")
        {
            column(locationCode; "Location Code")
            {
                Caption = 'Location code';
            }

            dataitem(HandlingUnitLine; "WHA Handling Unit Line")
            {
                DataItemLink = "Handling Unit No." = HandlingUnit."No.";
                SqlJoinType = InnerJoin;

                column(itemNo; "Item No.")
                {
                    Caption = 'Item number';
                }
                column(variantCode; "Variant Code")
                {
                    Caption = 'Variant code';
                }
                column(unitOfMeasureCode; "Unit of Measure Code")
                {
                    Caption = 'Unit of measure code';
                }
                column(quantity; Quantity)
                {
                    Caption = 'Quantity';
                    Method = Sum;
                }
            }
        }
    }
}
