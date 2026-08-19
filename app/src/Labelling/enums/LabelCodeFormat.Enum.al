namespace WarehouseAdvanced.Labelling;

enum 50600 "WHA Label Code Format" implements "WHA ILabelCodeFormat"
{
    Caption = 'Label code format';
    Extensible = true;
    DefaultImplementation = "WHA ILabelCodeFormat" = "WHA SSCC Format";

    value(0; WHASSCC)
    {
        Caption = 'SSCC (GS1)';
        Implementation = "WHA ILabelCodeFormat" = "WHA SSCC Format";
    }
    value(1; WHASequential)
    {
        Caption = 'Sequential licence plate';
        Implementation = "WHA ILabelCodeFormat" = "WHA Sequential Format";
    }
}
