namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

enumextension 55501 "WHA Count Activity Provider" extends "WHA Activity Provider"
{
    value(55500; WHACounting)
    {
        Caption = 'Counting';
        Implementation = "WHA IActivityCues" = "WHA Count Activity Cues";
    }
}
