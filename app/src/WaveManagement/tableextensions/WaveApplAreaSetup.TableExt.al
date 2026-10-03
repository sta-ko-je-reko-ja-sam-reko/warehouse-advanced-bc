namespace WarehouseAdvanced.WaveManagement;

using System.Environment.Configuration;

tableextension 55150 "WHA Wave Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55150; "WHA Wave Management"; Boolean)
        {
            Caption = 'Wave management';
            DataClassification = SystemMetadata;
        }
    }
}
