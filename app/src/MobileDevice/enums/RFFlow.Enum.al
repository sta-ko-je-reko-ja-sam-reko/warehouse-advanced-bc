namespace WarehouseAdvanced.MobileDevice;

enum 50101 "WHA RF Flow" implements "WHA IRFFlow"
{
    Caption = 'Handheld flow';
    Extensible = true;
    DefaultImplementation = "WHA IRFFlow" = "WHA RF Standard Flow";

    value(0; WHAStandard)
    {
        Caption = 'Standard';
        Implementation = "WHA IRFFlow" = "WHA RF Standard Flow";
    }
}
