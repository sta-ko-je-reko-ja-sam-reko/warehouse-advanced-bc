namespace WarehouseAdvanced.DirectedWork;

enum 50201 "WHA Warehouse Task Status"
{
    Caption = 'Warehouse task status';
    Extensible = true;

    value(0; WHACreated)
    {
        Caption = 'Created';
    }
    value(1; WHAReleased)
    {
        Caption = 'Released';
    }
    value(2; WHAAssigned)
    {
        Caption = 'Assigned';
    }
    value(3; WHAInProgress)
    {
        Caption = 'In progress';
    }
    value(4; WHACompleted)
    {
        Caption = 'Completed';
    }
    value(5; WHACancelled)
    {
        Caption = 'Cancelled';
    }
}
