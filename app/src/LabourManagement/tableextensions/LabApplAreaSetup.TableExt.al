namespace WarehouseAdvanced.LabourManagement;

using System.Environment.Configuration;

tableextension 50350 "WHA Lab. Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50350; "WHA Labour Management"; Boolean)
        {
            Caption = 'Labour management';
            DataClassification = SystemMetadata;
        }
    }
}
