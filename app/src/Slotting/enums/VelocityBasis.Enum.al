namespace WarehouseAdvanced.Slotting;

enum 50301 "WHA Velocity Basis" implements "WHA IVelocityBasis"
{
    Caption = 'Velocity basis';
    Extensible = true;
    DefaultImplementation = "WHA IVelocityBasis" = "WHA Velocity By Movements";

    value(0; WHAByMovements)
    {
        Caption = 'How often it is picked';
        Implementation = "WHA IVelocityBasis" = "WHA Velocity By Movements";
    }
    value(1; WHAByQuantity)
    {
        Caption = 'How much of it is picked';
        Implementation = "WHA IVelocityBasis" = "WHA Velocity By Quantity";
    }
}
