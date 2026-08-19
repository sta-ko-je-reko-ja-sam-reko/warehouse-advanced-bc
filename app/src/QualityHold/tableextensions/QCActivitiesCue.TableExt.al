namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;

tableextension 50551 "WHA QC Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(50550; "WHA Goods On Hold"; Integer)
        {
            Caption = 'Goods on hold';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many handling units are stopped and cannot be used.';
            Editable = false;
        }
        field(50551; "WHA Holds To Decide"; Integer)
        {
            Caption = 'Holds waiting for a decision';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many held units nobody has decided what to do with. These are the ones that get forgotten.';
            Editable = false;
        }
    }
}
