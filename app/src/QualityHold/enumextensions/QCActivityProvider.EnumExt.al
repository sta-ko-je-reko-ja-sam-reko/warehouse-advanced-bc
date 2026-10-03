namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;

enumextension 55551 "WHA QC Activity Provider" extends "WHA Activity Provider"
{
    value(55550; WHAQualityHold)
    {
        Caption = 'QualityHold';
        Implementation = "WHA IActivityCues" = "WHA QC Activity Cues";
    }
}
