namespace WarehouseAdvanced.MobileDevice;

using System.Environment.Configuration;

tableextension 50100 "WHA RF Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(50100; "WHA Mobile Device"; Boolean)
        {
            Caption = 'Mobile device';
            DataClassification = SystemMetadata;
        }
    }
}
