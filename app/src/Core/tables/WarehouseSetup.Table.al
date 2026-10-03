namespace WarehouseAdvanced.Core;

table 55000 "WHA Warehouse Setup"
{
    Caption = 'Warehouse advanced setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary key';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
