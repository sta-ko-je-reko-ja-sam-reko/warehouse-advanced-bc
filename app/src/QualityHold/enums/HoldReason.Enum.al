namespace WarehouseAdvanced.QualityHold;

enum 50550 "WHA Hold Reason"
{
    Caption = 'Hold reason';
    Extensible = true;

    value(0; WHAInspection)
    {
        Caption = 'Waiting for inspection';
    }
    value(1; WHADamaged)
    {
        Caption = 'Damaged';
    }
    value(2; WHAExpired)
    {
        Caption = 'Expired or out of date';
    }
    value(3; WHAWrongGoods)
    {
        Caption = 'Not what was expected';
    }
    value(4; WHAComplaint)
    {
        Caption = 'Customer complaint';
    }
    value(5; WHAOther)
    {
        Caption = 'Other';
    }
}
