namespace WarehouseAdvanced.Replenishment;

enum 50250 "WHA Repl. Method" implements "WHA IReplMethod"
{
    Caption = 'Replenishment method';
    Extensible = true;
    DefaultImplementation = "WHA IReplMethod" = "WHA Repl. Bin Content";

    value(0; WHABinContent)
    {
        Caption = 'Bin content';
        Implementation = "WHA IReplMethod" = "WHA Repl. Bin Content";
    }
    value(1; WHAHandlingUnits)
    {
        Caption = 'Handling units';
        Implementation = "WHA IReplMethod" = "WHA Repl. Handling Units";
    }
}
