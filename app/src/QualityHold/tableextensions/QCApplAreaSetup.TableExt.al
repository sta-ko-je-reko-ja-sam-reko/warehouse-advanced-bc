namespace WarehouseAdvanced.QualityHold;

using System.Environment.Configuration;

tableextension 50550 "WHA QC Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50550; "WHA Quality Hold"; Boolean)
        {
            Caption = 'Quality hold';
            DataClassification = SystemMetadata;
        }
    }
}
