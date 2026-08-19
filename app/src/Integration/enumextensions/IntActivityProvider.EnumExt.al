namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

enumextension 50651 "WHA Int Activity Provider" extends "WHA Activity Provider"
{
    value(50650; WHAIntegration)
    {
        Caption = 'Integration';
        Implementation = "WHA IActivityCues" = "WHA Int Activity Cues";
    }
}
