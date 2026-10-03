namespace WarehouseAdvanced.QualityHold;

enum 55551 "WHA Hold Status"
{
    Caption = 'Hold status';
    Extensible = true;

    value(0; WHAOnHold)
    {
        Caption = 'On hold';
    }
    value(1; WHAReleased)
    {
        Caption = 'Released';
    }
}
