namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

tableextension 50401 "WHA Pack Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(50400; "WHA Cartons Being Packed"; Integer)
        {
            Caption = 'Cartons being packed';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many cartons are open at a packing bench right now.';
            Editable = false;
        }
    }
}
