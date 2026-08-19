namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

enumextension 50151 "WHA Wave Activity Provider" extends "WHA Activity Provider"
{
    value(50150; WHAWaveManagement)
    {
        Caption = 'WaveManagement';
        Implementation = "WHA IActivityCues" = "WHA Wave Activity Cues";
    }
}
