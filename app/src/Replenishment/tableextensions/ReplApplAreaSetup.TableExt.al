namespace WarehouseAdvanced.Replenishment;

using System.Environment.Configuration;

tableextension 55250 "WHA Repl. Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55250; "WHA Replenishment"; Boolean)
        {
            Caption = 'Replenishment';
            DataClassification = SystemMetadata;
        }
    }
}
