namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

enumextension 55550 "WHA HU Status Hold" extends "WHA Handling Unit Status"
{
    value(55550; WHAOnHold)
    {
        Caption = 'On hold';
    }
    value(55551; WHAScrapped)
    {
        Caption = 'Scrapped';
    }
}
