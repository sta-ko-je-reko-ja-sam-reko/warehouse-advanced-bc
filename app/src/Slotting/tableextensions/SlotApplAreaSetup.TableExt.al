namespace WarehouseAdvanced.Slotting;

using System.Environment.Configuration;

tableextension 50300 "WHA Slot. Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50300; "WHA Slotting"; Boolean)
        {
            Caption = 'Slotting';
            DataClassification = SystemMetadata;
        }
    }
}
