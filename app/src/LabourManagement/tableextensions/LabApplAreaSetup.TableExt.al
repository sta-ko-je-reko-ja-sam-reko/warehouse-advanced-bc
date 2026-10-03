namespace WarehouseAdvanced.LabourManagement;

using System.Environment.Configuration;

tableextension 55350 "WHA Lab. Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55350; "WHA Labour Management"; Boolean)
        {
            Caption = 'Labour management';
            DataClassification = SystemMetadata;
        }
    }
}
