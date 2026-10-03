namespace WarehouseAdvanced.DockYard;

using System.Environment.Configuration;

tableextension 55450 "WHA Dock Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55450; "WHA Dock Yard"; Boolean)
        {
            Caption = 'Dock and yard';
            DataClassification = SystemMetadata;
        }
    }
}
