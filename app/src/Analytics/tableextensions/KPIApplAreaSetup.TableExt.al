namespace WarehouseAdvanced.Analytics;

using System.Environment.Configuration;

tableextension 55700 "WHA KPI Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55700; "WHA Analytics"; Boolean)
        {
            Caption = 'Analytics';
            DataClassification = SystemMetadata;
        }
    }
}
