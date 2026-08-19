namespace WarehouseAdvanced.Packing;

enum 50400 "WHA Pack Session Status"
{
    Caption = 'Packing status';
    Extensible = true;

    value(0; WHAPacking)
    {
        Caption = 'Packing';
    }
    value(1; WHAVerified)
    {
        Caption = 'Verified';
    }
    value(2; WHAClosed)
    {
        Caption = 'Closed';
    }
    value(3; WHACancelled)
    {
        Caption = 'Cancelled';
    }
}
