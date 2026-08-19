namespace WarehouseAdvanced.WaveManagement;

enum 50150 "WHA Wave Status"
{
    Caption = 'Wave status';
    Extensible = true;

    value(0; WHAOpen)
    {
        Caption = 'Open';
    }
    value(1; WHAReleased)
    {
        Caption = 'Released';
    }
    value(2; WHACompleted)
    {
        Caption = 'Completed';
    }
    value(3; WHACancelled)
    {
        Caption = 'Cancelled';
    }
}
