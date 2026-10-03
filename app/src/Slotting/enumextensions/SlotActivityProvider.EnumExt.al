namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

enumextension 55301 "WHA Slot Activity Provider" extends "WHA Activity Provider"
{
    value(55300; WHASlotting)
    {
        Caption = 'Slotting';
        Implementation = "WHA IActivityCues" = "WHA Slot Activity Cues";
    }
}
