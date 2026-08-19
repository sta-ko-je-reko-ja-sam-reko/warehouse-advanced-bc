namespace WarehouseAdvanced.Counting;

using Microsoft.Warehouse.Ledger;

query 50509 "WHA Whse Stock By Lot"
{
    QueryType = Normal;
    Caption = 'Warehouse stock by lot';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(WarehouseEntry; "Warehouse Entry")
        {
            column(binCode; "Bin Code")
            {
                Caption = 'Bin code';
            }
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
            column(lotNo; "Lot No.")
            {
                Caption = 'Lot number';
            }
            column(serialNo; "Serial No.")
            {
                Caption = 'Serial number';
            }
            column(quantity; Quantity)
            {
                Caption = 'Quantity';
                Method = Sum;
            }

            filter(locationCodeFilter; "Location Code")
            {
                Caption = 'Location code filter';
            }
        }
    }
}
