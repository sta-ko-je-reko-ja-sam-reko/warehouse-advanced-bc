namespace WarehouseAdvanced.DirectedWork;

enum 50204 "WHA Open Work Policy" implements "WHA IOpenWorkPolicy"
{
    Caption = 'Open work on posting';
    Extensible = true;
    DefaultImplementation = "WHA IOpenWorkPolicy" = "WHA Allow Open Work";

    value(0; WHAAllow)
    {
        Caption = 'Let the document be posted';
        Implementation = "WHA IOpenWorkPolicy" = "WHA Allow Open Work";
    }
    value(1; WHABlock)
    {
        Caption = 'Hold the document until the work is finished';
        Implementation = "WHA IOpenWorkPolicy" = "WHA Block Open Work";
    }
}
