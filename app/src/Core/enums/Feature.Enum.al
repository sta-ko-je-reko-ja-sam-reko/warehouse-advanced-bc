namespace WarehouseAdvanced.Core;

enum 50000 "WHA Feature" implements "WHA IFeatureSetup"
{
    Caption = 'Warehouse advanced feature';
    Extensible = true;
    DefaultImplementation = "WHA IFeatureSetup" = "WHA Default Feature Setup";

    value(0; WHANone)
    {
        Caption = 'None';
    }
}
