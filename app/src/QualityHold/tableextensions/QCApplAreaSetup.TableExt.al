namespace WarehouseAdvanced.QualityHold;

using System.Environment.Configuration;

tableextension 55550 "WHA QC Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55550; "WHA Quality Hold"; Boolean)
        {
            Caption = 'Quality hold';
            DataClassification = SystemMetadata;
        }
    }
}
