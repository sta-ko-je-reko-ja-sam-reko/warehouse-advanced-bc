namespace WarehouseAdvanced.LabourManagement;

enum 50352 "WHA Labour Standard Basis" implements "WHA ILabourStandard"
{
    Caption = 'Standard basis';
    Extensible = true;
    DefaultImplementation = "WHA ILabourStandard" = "WHA Std. Fixed Plus Unit";

    value(0; WHAFixedPlusUnit)
    {
        Caption = 'Per job plus per unit';
        Implementation = "WHA ILabourStandard" = "WHA Std. Fixed Plus Unit";
    }
    value(1; WHAFixedOnly)
    {
        Caption = 'Per job only';
        Implementation = "WHA ILabourStandard" = "WHA Std. Fixed Only";
    }
}
