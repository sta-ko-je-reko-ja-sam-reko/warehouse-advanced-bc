namespace WarehouseAdvanced.Posting;

enum 50750 "WHA Posting Type"
{
    Caption = 'Posting type';
    Extensible = true;

    value(0; WHAPositiveAdjustment)
    {
        Caption = 'Positive adjustment';
    }
    value(1; WHANegativeAdjustment)
    {
        Caption = 'Negative adjustment';
    }
}
