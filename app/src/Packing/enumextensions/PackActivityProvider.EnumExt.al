namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

enumextension 50401 "WHA Pack Activity Provider" extends "WHA Activity Provider"
{
    value(50400; WHAPacking)
    {
        Caption = 'Packing';
        Implementation = "WHA IActivityCues" = "WHA Pack Activity Cues";
    }
}
