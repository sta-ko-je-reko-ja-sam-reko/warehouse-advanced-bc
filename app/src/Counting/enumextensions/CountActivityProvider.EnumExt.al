namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

enumextension 50501 "WHA Count Activity Provider" extends "WHA Activity Provider"
{
    value(50500; WHACounting)
    {
        Caption = 'Counting';
        Implementation = "WHA IActivityCues" = "WHA Count Activity Cues";
    }
}
