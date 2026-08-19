namespace WarehouseAdvanced.Core;

enum 50001 "WHA Setup Step Status"
{
    Caption = 'Warehouse advanced setup step status';
    Extensible = false;

    value(0; WHANotStarted)
    {
        Caption = 'Not started';
    }
    value(1; WHAInProgress)
    {
        Caption = 'In progress';
    }
    value(2; WHACompleted)
    {
        Caption = 'Completed';
    }
}
