namespace WarehouseAdvanced.Counting;

enum 50501 "WHA Count Selection" implements "WHA ICountSelection"
{
    Caption = 'Count selection';
    Extensible = true;
    DefaultImplementation = "WHA ICountSelection" = "WHA Count Bin Selection";

    value(0; WHABinContent)
    {
        Caption = 'Bins';
        Implementation = "WHA ICountSelection" = "WHA Count Bin Selection";
    }
    value(1; WHAHandlingUnits)
    {
        Caption = 'Handling units';
        Implementation = "WHA ICountSelection" = "WHA Count HU Selection";
    }
    value(2; WHABinContentByLot)
    {
        Caption = 'Bins by lot';
        Implementation = "WHA ICountSelection" = "WHA Count Bin Lot Selection";
    }
}
