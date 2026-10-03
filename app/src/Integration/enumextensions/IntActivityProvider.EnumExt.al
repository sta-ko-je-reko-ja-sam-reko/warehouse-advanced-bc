namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

enumextension 55651 "WHA Int Activity Provider" extends "WHA Activity Provider"
{
    value(55650; WHAIntegration)
    {
        Caption = 'Integration';
        Implementation = "WHA IActivityCues" = "WHA Int Activity Cues";
    }
}
