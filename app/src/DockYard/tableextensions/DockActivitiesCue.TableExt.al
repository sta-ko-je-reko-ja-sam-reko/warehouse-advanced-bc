namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

tableextension 50451 "WHA Dock Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(50450; "WHA Vehicles On Site"; Integer)
        {
            Caption = 'Vehicles on site';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many vehicles have arrived and not yet left.';
            Editable = false;
        }
        field(50451; "WHA Vehicles Waiting"; Integer)
        {
            Caption = 'Vehicles waiting for a door';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many vehicles are on site and not yet at a door.';
            Editable = false;
        }
    }
}
