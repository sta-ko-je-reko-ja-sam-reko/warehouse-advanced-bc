namespace WarehouseAdvanced.DockYard;

enum 50452 "WHA Appointment Status"
{
    Caption = 'Appointment status';
    Extensible = true;

    value(0; WHABooked)
    {
        Caption = 'Booked';
    }
    value(1; WHAArrived)
    {
        Caption = 'Arrived';
    }
    value(2; WHAAtDoor)
    {
        Caption = 'At the door';
    }
    value(3; WHADeparted)
    {
        Caption = 'Departed';
    }
    value(4; WHACancelled)
    {
        Caption = 'Cancelled';
    }
}
