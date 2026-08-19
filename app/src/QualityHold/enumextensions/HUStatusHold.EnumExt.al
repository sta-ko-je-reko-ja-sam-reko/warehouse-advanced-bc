namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

enumextension 50550 "WHA HU Status Hold" extends "WHA Handling Unit Status"
{
    value(50550; WHAOnHold)
    {
        Caption = 'On hold';
    }
    value(50551; WHAScrapped)
    {
        Caption = 'Scrapped';
    }
}
