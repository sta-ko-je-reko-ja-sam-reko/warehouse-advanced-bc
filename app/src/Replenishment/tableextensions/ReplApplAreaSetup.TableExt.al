namespace WarehouseAdvanced.Replenishment;

using System.Environment.Configuration;

tableextension 50250 "WHA Repl. Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50250; "WHA Replenishment"; Boolean)
        {
            Caption = 'Replenishment';
            DataClassification = SystemMetadata;
        }
    }
}
