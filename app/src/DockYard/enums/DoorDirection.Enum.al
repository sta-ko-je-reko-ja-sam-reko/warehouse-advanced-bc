namespace WarehouseAdvanced.DockYard;

enum 50451 "WHA Door Direction"
{
    Caption = 'Door direction';
    Extensible = true;

    value(0; WHAInbound)
    {
        Caption = 'Inbound only';
    }
    value(1; WHAOutbound)
    {
        Caption = 'Outbound only';
    }
    value(2; WHABoth)
    {
        Caption = 'Both ways';
    }
}
