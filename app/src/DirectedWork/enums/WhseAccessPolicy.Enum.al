namespace WarehouseAdvanced.DirectedWork;

enum 50205 "WHA Whse. Access Policy" implements "WHA IWhseAccessPolicy"
{
    Caption = 'Who may be given work';
    Extensible = true;
    DefaultImplementation = "WHA IWhseAccessPolicy" = "WHA Any User Works";

    value(0; WHAAnyUser)
    {
        Caption = 'Anybody with permission to use the app';
    }
    value(1; WHAWhseEmployees)
    {
        Caption = 'Only warehouse employees at that location';
        Implementation = "WHA IWhseAccessPolicy" = "WHA Whse. Employees Only";
    }
}
