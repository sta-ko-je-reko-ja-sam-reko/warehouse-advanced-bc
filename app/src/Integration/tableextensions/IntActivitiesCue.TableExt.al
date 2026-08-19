namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

tableextension 50651 "WHA Int Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(50650; "WHA Messages Waiting"; Integer)
        {
            Caption = 'Messages waiting';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many messages have arrived and not been worked through yet.';
            Editable = false;
        }
        field(50651; "WHA Messages Failed"; Integer)
        {
            Caption = 'Messages that failed';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many messages could not be handled. Each one is something the other system believes it told you.';
            Editable = false;
        }
    }
}
