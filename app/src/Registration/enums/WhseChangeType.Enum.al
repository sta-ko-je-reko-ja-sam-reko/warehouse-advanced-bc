namespace WarehouseAdvanced.Registration;

enum 50801 "WHA Whse. Change Type"
{
    Caption = 'Warehouse change type';
    Extensible = true;

    value(0; WHAMove)
    {
        Caption = 'Moved from one bin to another';
    }
    value(1; WHAIncrease)
    {
        Caption = 'Added to a bin';
    }
    value(2; WHADecrease)
    {
        Caption = 'Taken out of a bin';
    }
}
