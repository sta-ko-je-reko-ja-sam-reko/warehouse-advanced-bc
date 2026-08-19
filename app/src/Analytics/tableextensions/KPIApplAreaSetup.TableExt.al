namespace WarehouseAdvanced.Analytics;

using System.Environment.Configuration;

tableextension 50700 "WHA KPI Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50700; "WHA Analytics"; Boolean)
        {
            Caption = 'Analytics';
            DataClassification = SystemMetadata;
        }
    }
}
