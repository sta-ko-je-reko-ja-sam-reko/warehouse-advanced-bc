namespace WarehouseAdvanced.Integration;

using System.Environment.Configuration;

tableextension 55650 "WHA Int. Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55650; "WHA Integration"; Boolean)
        {
            Caption = 'Integration';
            DataClassification = SystemMetadata;
        }
    }
}
