namespace WarehouseAdvanced.DirectedWork;

enum 50202 "WHA Whse. Short Reason"
{
    Caption = 'Short reason';
    Extensible = true;

    value(0; WHANone)
    {
        Caption = ' ';
    }
    value(1; WHANotFound)
    {
        Caption = 'Nothing in the bin';
    }
    value(2; WHANotEnough)
    {
        Caption = 'Not enough in the bin';
    }
    value(3; WHADamaged)
    {
        Caption = 'Damaged';
    }
    value(4; WHACannotReach)
    {
        Caption = 'Cannot reach it';
    }
}
