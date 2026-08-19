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
    value(5; WHAWarehouseReceiptRelease)
    {
        Caption = 'Release warehouse receipt';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Receipt Release";
    }
    value(6; WHAWarehouseShipmentRelease)
    {
        Caption = 'Release warehouse shipment';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Shipment Release";
    }
    value(7; WHAInventoryAdjustment)
    {
        Caption = 'Inventory adjustment';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Inventory Adjust";
    }
    value(8; WHACountRequest)
    {
        Caption = 'Count request';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Count Request";
    }
    value(9; WHAWarehouseReceiptDone)
    {
        Caption = 'Warehouse receipt completed';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Receipt Completed";
    }
    value(10; WHAWarehouseShipmentDone)
    {
        Caption = 'Warehouse shipment completed';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Shipment Completed";
    }
    value(11; WHACountResult)
    {
        Caption = 'Count result';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Count Result";
    }
    value(12; WHAStockPosition)
    {
        Caption = 'Stock position';
        Implementation = "WHA IIntMessageHandler" = "WHA Int. Stock Position";
    }
}
