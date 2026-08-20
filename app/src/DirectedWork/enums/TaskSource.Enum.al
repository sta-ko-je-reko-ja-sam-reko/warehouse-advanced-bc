namespace WarehouseAdvanced.DirectedWork;

enum 50203 "WHA Task Source" implements "WHA ITaskSource"
{
    Caption = 'Task source';
    Extensible = true;
    DefaultImplementation = "WHA ITaskSource" = "WHA Src Manual";

    value(0; WHAManual)
    {
        Caption = 'Created by hand';
        Implementation = "WHA ITaskSource" = "WHA Src Manual";
    }
    value(1; WHAWhseReceipt)
    {
        Caption = 'Warehouse receipt';
        Implementation = "WHA ITaskSource" = "WHA Src Whse. Receipt";
    }
    value(2; WHAWhseShipment)
    {
        Caption = 'Warehouse shipment';
        Implementation = "WHA ITaskSource" = "WHA Src Whse. Shipment";
    }
    value(3; WHAMovementWksh)
    {
        Caption = 'Movement worksheet';
        Implementation = "WHA ITaskSource" = "WHA Src Movement Wksh.";
    }
    value(4; WHAWhseActivity)
    {
        Caption = 'Warehouse activity';
        Implementation = "WHA ITaskSource" = "WHA Src Whse. Activity";
    }
}
