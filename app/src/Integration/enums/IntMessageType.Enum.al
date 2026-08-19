namespace WarehouseAdvanced.Integration;

enum 50652 "WHA Int. Message Type" implements "WHA IIntMessageHandler"
{
    Caption = 'Integration message type';
    Extensible = true;
    DefaultImplementation = "WHA IIntMessageHandler" = "WHA Int. Unhandled Message";

    value(0; WHAUnknown)
    {
        Caption = 'Unknown';
    }
    value(1; WHAHandlingUnitReceived)
    {
        Caption = 'Handling unit received';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. HU Received";
    }
    value(2; WHAWarehouseTaskRequest)
    {
        Caption = 'Warehouse task request';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Task Request";
    }
    value(3; WHAWarehouseTaskConfirmed)
    {
        Caption = 'Warehouse task confirmed';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Task Confirm";
    }
    value(4; WHAHandlingUnitShipped)
    {
        Caption = 'Handling unit shipped';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. HU Shipped";
    }
}
