namespace WarehouseAdvanced.DockYard;

enum 50453 "WHA Door Selection" implements "WHA IDoorSelection"
{
    Caption = 'Door selection';
    Extensible = true;
    DefaultImplementation = "WHA IDoorSelection" = "WHA Door First Free";

    value(0; WHAFirstFree)
    {
        Caption = 'The first free door';
        Implementation = "WHA IDoorSelection" = "WHA Door First Free";
    }
    value(1; WHALeastBusy)
    {
        Caption = 'The least busy door';
        Implementation = "WHA IDoorSelection" = "WHA Door Least Busy";
    }
}
