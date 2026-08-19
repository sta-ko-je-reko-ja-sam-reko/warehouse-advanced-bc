namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

enumextension 50301 "WHA Slot Activity Provider" extends "WHA Activity Provider"
{
    value(50300; WHASlotting)
    {
        Caption = 'Slotting';
        Implementation = "WHA IActivityCues" = "WHA Slot Activity Cues";
    }
}
