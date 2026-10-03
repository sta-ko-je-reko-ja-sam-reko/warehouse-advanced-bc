namespace WarehouseAdvanced.Labelling;

using System.Environment.Configuration;

tableextension 55600 "WHA Label Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55600; "WHA Labelling"; Boolean)
        {
            Caption = 'Labelling';
            DataClassification = SystemMetadata;
        }
    }
}
