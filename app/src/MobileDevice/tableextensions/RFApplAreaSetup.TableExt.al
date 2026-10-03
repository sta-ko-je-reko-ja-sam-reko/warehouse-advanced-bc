namespace WarehouseAdvanced.MobileDevice;

using System.Environment.Configuration;

tableextension 55100 "WHA RF Appl. Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(55100; "WHA Mobile Device"; Boolean)
        {
            Caption = 'Mobile device';
            DataClassification = SystemMetadata;
        }
    }
}
