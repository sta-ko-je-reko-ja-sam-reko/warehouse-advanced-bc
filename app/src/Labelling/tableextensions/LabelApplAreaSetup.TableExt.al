namespace WarehouseAdvanced.Labelling;

using System.Environment.Configuration;

tableextension 50600 "WHA Label Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50600; "WHA Labelling"; Boolean)
        {
            Caption = 'Labelling';
            DataClassification = SystemMetadata;
        }
    }
}
