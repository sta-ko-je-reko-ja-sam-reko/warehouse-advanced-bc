namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

enumextension 50451 "WHA Dock Activity Provider" extends "WHA Activity Provider"
{
    value(50450; WHADockYard)
    {
        Caption = 'DockYard';
        Implementation = "WHA IActivityCues" = "WHA Dock Activity Cues";
    }
}
