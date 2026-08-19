namespace WarehouseAdvanced.Integration;

using System.Environment.Configuration;

tableextension 50650 "WHA Int. Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50650; "WHA Integration"; Boolean)
        {
            Caption = 'Integration';
            DataClassification = SystemMetadata;
        }
    }
}
