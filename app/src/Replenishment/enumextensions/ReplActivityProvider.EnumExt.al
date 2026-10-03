namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

enumextension 55251 "WHA Repl Activity Provider" extends "WHA Activity Provider"
{
    value(55250; WHAReplenishment)
    {
        Caption = 'Replenishment';
        Implementation = "WHA IActivityCues" = "WHA Repl Activity Cues";
    }
}
