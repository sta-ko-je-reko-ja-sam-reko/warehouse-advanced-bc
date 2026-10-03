namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

tableextension 55401 "WHA Pack Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(55400; "WHA Cartons Being Packed"; Integer)
        {
            Caption = 'Cartons being packed';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many cartons are open at a packing bench right now.';
            Editable = false;
        }
    }
}
