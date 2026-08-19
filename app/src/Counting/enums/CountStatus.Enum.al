namespace WarehouseAdvanced.Counting;

enum 50500 "WHA Count Status"
{
    Caption = 'Count sheet status';
    Extensible = true;

    value(0; WHAOpen)
    {
        Caption = 'Open';
    }
    value(1; WHACounting)
    {
        Caption = 'Counting';
    }
    value(2; WHACounted)
    {
        Caption = 'Counted';
    }
    value(3; WHAClosed)
    {
        Caption = 'Closed';
    }
    value(4; WHACancelled)
    {
        Caption = 'Cancelled';
    }
}
