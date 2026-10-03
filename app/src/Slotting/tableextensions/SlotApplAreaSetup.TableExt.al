namespace WarehouseAdvanced.Slotting;

using System.Environment.Configuration;

tableextension 55300 "WHA Slot. Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55300; "WHA Slotting"; Boolean)
        {
            Caption = 'Slotting';
            DataClassification = SystemMetadata;
        }
    }
}
