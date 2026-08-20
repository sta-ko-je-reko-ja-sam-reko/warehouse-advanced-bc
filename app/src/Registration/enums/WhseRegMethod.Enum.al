namespace WarehouseAdvanced.Registration;

enum 50800 "WHA Whse. Reg. Method" implements "WHA IWhseRegistration"
{
    Caption = 'Warehouse registration method';
    Extensible = true;
    DefaultImplementation = "WHA IWhseRegistration" = "WHA No Whse. Registration";

    value(0; WHANone)
    {
        Caption = 'Do not tell Business Central';
        Implementation = "WHA IWhseRegistration" = "WHA No Whse. Registration";
    }
    value(1; WHAWhseMovement)
    {
        Caption = 'Register a warehouse movement';
        Implementation = "WHA IWhseRegistration" = "WHA Whse. Jnl. Registration";
    }
}
