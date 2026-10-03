namespace WarehouseAdvanced.Counting;

using System.Environment.Configuration;

tableextension 55500 "WHA Count Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55500; "WHA Counting"; Boolean)
        {
            Caption = 'Counting';
            DataClassification = SystemMetadata;
        }
    }
}
