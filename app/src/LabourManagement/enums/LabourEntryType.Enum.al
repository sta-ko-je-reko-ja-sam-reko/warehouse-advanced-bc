namespace WarehouseAdvanced.LabourManagement;

enum 50350 "WHA Labour Entry Type"
{
    Caption = 'Labour entry type';
    Extensible = true;

    value(0; WHADirect)
    {
        Caption = 'On a job';
    }
    value(1; WHAIndirect)
    {
        Caption = 'Not on a job';
    }
}
