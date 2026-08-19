namespace WarehouseAdvanced.DirectedWork;

enum 50200 "WHA Warehouse Task Type"
{
    Caption = 'Warehouse task type';
    Extensible = true;

    value(0; WHAPutAway)
    {
        Caption = 'Put-away';
    }
    value(1; WHAPick)
    {
        Caption = 'Pick';
    }
    value(2; WHAMovement)
    {
        Caption = 'Movement';
    }
    value(3; WHAReplenishment)
    {
        Caption = 'Replenishment';
    }
    value(4; WHACount)
    {
        Caption = 'Count';
    }
}
