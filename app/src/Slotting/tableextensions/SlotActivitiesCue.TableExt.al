namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

tableextension 55301 "WHA Slot Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(55300; "WHA Slotting Proposals Open"; Integer)
        {
            Caption = 'Slotting proposals waiting';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many proposed moves nobody has accepted or rejected yet.';
            Editable = false;
        }
    }
}
