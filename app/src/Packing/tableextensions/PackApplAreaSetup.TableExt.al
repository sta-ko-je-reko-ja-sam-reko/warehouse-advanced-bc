namespace WarehouseAdvanced.Packing;

using System.Environment.Configuration;

tableextension 55400 "WHA Pack Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55400; "WHA Packing"; Boolean)
        {
            Caption = 'Packing';
            DataClassification = SystemMetadata;
        }
    }
}
