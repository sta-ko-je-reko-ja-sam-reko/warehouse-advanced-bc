namespace WarehouseAdvanced.MobileDevice;

enum 50100 "WHA RF Step"
{
    Caption = 'Handheld step';
    Extensible = true;

    value(0; WHASignIn)
    {
        Caption = 'Sign in';
    }
    value(1; WHAGetWork)
    {
        Caption = 'Get work';
    }
    value(2; WHAScanFrom)
    {
        Caption = 'Scan the bin to take from';
    }
    value(3; WHAScanUnit)
    {
        Caption = 'Scan the handling unit';
    }
    value(4; WHAScanTo)
    {
        Caption = 'Scan the bin to put in';
    }
    value(5; WHAConfirm)
    {
        Caption = 'Confirm';
    }
}
