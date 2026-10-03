namespace WarehouseAdvanced.HandlingUnit;

using System.Environment.Configuration;

tableextension 55050 "WHA Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55050; "WHA Handling Units"; Boolean)
        {
            Caption = 'Handling units';
            DataClassification = SystemMetadata;
        }
    }
}
