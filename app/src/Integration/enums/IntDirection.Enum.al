namespace WarehouseAdvanced.Integration;

enum 50650 "WHA Int. Direction"
{
    Caption = 'Integration direction';
    Extensible = false;

    value(0; WHAInbound)
    {
        Caption = 'Inbound';
    }
    value(1; WHAOutbound)
    {
        Caption = 'Outbound';
    }
}
