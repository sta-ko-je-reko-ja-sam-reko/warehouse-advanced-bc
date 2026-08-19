namespace WarehouseAdvanced.QualityHold;

enum 50552 "WHA Hold Disposition" implements "WHA IHoldDisposition"
{
    Caption = 'Disposition';
    Extensible = true;
    DefaultImplementation = "WHA IHoldDisposition" = "WHA Disp. Pending";

    value(0; WHAPending)
    {
        Caption = 'Not decided yet';
        Implementation = "WHA IHoldDisposition" = "WHA Disp. Pending";
    }
    value(1; WHAReleaseToStock)
    {
        Caption = 'Release back into stock';
        Implementation = "WHA IHoldDisposition" = "WHA Disp. Release";
    }
    value(2; WHARework)
    {
        Caption = 'Rework';
        Implementation = "WHA IHoldDisposition" = "WHA Disp. Rework";
    }
    value(3; WHAScrap)
    {
        Caption = 'Scrap';
        Implementation = "WHA IHoldDisposition" = "WHA Disp. Scrap";
    }
}
