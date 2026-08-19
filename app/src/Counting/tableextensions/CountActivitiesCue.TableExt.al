namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

tableextension 50501 "WHA Count Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(50500; "WHA Count Sheets Out"; Integer)
        {
            Caption = 'Count sheets on the floor';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many count sheets have been sent out and are still being counted.';
            Editable = false;
        }
        field(50501; "WHA Counts To Approve"; Integer)
        {
            Caption = 'Counts waiting for approval';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many counted sheets are waiting for somebody to accept a difference before they can be closed.';
            Editable = false;
        }
    }
}
