namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

tableextension 50151 "WHA Wave Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(50150; "WHA Waves Open"; Integer)
        {
            Caption = 'Waves being built';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many waves are still being put together and have not gone to the floor.';
            Editable = false;
        }
        field(50151; "WHA Waves On Floor"; Integer)
        {
            Caption = 'Waves on the floor';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many waves have been released and are not finished.';
            Editable = false;
        }
    }
}
