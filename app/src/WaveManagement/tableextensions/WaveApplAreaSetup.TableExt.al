namespace WarehouseAdvanced.WaveManagement;

using System.Environment.Configuration;

tableextension 50150 "WHA Wave Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50150; "WHA Wave Management"; Boolean)
        {
            Caption = 'Wave management';
            DataClassification = SystemMetadata;
        }
    }
}
