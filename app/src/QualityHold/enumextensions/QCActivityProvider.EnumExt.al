namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;

enumextension 50551 "WHA QC Activity Provider" extends "WHA Activity Provider"
{
    value(50550; WHAQualityHold)
    {
        Caption = 'QualityHold';
        Implementation = "WHA IActivityCues" = "WHA QC Activity Cues";
    }
}
