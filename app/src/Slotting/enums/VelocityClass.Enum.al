namespace WarehouseAdvanced.Slotting;

enum 50300 "WHA Velocity Class"
{
    Caption = 'Velocity class';
    Extensible = true;

    value(0; WHAUnclassified)
    {
        Caption = 'Not classified';
    }
    value(1; WHAClassA)
    {
        Caption = 'A - fast';
    }
    value(2; WHAClassB)
    {
        Caption = 'B - medium';
    }
    value(3; WHAClassC)
    {
        Caption = 'C - slow';
    }
}
