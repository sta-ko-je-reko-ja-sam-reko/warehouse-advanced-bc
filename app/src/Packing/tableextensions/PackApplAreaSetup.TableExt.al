namespace WarehouseAdvanced.Packing;

using System.Environment.Configuration;

tableextension 50400 "WHA Pack Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50400; "WHA Packing"; Boolean)
        {
            Caption = 'Packing';
            DataClassification = SystemMetadata;
        }
    }
}
