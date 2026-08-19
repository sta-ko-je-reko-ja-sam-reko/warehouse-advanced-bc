namespace WarehouseAdvanced.DockYard;

enum 50450 "WHA Dock Direction"
{
    Caption = 'Dock direction';
    Extensible = true;

    value(0; WHAInbound)
    {
        Caption = 'Inbound';
    }
    value(1; WHAOutbound)
    {
        Caption = 'Outbound';
    }
}
