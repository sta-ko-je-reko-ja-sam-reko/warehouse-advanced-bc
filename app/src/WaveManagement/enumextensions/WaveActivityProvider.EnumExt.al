namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

enumextension 55151 "WHA Wave Activity Provider" extends "WHA Activity Provider"
{
    value(55150; WHAWaveManagement)
    {
        Caption = 'WaveManagement';
        Implementation = "WHA IActivityCues" = "WHA Wave Activity Cues";
    }
}
