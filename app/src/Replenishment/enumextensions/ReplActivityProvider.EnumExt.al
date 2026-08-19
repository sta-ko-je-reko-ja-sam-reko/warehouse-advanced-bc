namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

enumextension 50251 "WHA Repl Activity Provider" extends "WHA Activity Provider"
{
    value(50250; WHAReplenishment)
    {
        Caption = 'Replenishment';
        Implementation = "WHA IActivityCues" = "WHA Repl Activity Cues";
    }
}
