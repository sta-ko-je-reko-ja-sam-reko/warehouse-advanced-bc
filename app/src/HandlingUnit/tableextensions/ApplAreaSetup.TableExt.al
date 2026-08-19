namespace WarehouseAdvanced.HandlingUnit;

using System.Environment.Configuration;

tableextension 50050 "WHA Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50050; "WHA Handling Units"; Boolean)
        {
            Caption = 'Handling units';
            DataClassification = SystemMetadata;
        }
    }
}
