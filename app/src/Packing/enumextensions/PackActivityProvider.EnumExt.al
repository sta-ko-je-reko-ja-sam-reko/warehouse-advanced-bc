namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

enumextension 55401 "WHA Pack Activity Provider" extends "WHA Activity Provider"
{
    value(55400; WHAPacking)
    {
        Caption = 'Packing';
        Implementation = "WHA IActivityCues" = "WHA Pack Activity Cues";
    }
}
