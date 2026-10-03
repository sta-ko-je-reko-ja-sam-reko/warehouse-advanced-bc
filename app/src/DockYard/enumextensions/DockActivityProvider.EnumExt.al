namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

enumextension 55451 "WHA Dock Activity Provider" extends "WHA Activity Provider"
{
    value(55450; WHADockYard)
    {
        Caption = 'DockYard';
        Implementation = "WHA IActivityCues" = "WHA Dock Activity Cues";
    }
}
