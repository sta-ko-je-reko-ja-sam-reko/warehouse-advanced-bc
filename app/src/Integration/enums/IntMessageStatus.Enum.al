namespace WarehouseAdvanced.Integration;

enum 50651 "WHA Int. Message Status"
{
    Caption = 'Integration message status';
    Extensible = true;

    value(0; WHANew)
    {
        Caption = 'New';
    }
    value(1; WHAProcessed)
    {
        Caption = 'Processed';
    }
    value(2; WHAFailed)
    {
        Caption = 'Failed';
    }
    value(3; WHACancelled)
    {
        Caption = 'Cancelled';
    }
}
