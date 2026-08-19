namespace WarehouseAdvanced.HandlingUnit;

enum 50050 "WHA Handling Unit Status"
{
    Caption = 'Handling unit status';
    Extensible = true;

    value(0; WHAOpen)
    {
        Caption = 'Open';
    }
    value(1; WHAClosed)
    {
        Caption = 'Closed';
    }
    value(2; WHAShipped)
    {
        Caption = 'Shipped';
    }
}
