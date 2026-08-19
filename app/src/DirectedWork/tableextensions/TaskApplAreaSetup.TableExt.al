namespace WarehouseAdvanced.DirectedWork;

using System.Environment.Configuration;

tableextension 50200 "WHA Task Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50200; "WHA Directed Work"; Boolean)
        {
            Caption = 'Directed work';
            DataClassification = SystemMetadata;
        }
    }
}
