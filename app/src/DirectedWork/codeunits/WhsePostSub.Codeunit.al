namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Warehouse.Document;

codeunit 50212 "WHA Whse. Post Sub."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnBeforeRun, '', true, true)]
    local procedure OnBeforePostWarehouseReceipt(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        SourceType: Enum "WHA Task Source";
    begin
        OpenWorkMgt.Check(SourceType::WHAWhseReceipt, WarehouseReceiptLine."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", OnBeforeRun, '', true, true)]
    local procedure OnBeforePostWarehouseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        SourceType: Enum "WHA Task Source";
    begin
        OpenWorkMgt.Check(SourceType::WHAWhseShipment, WarehouseShipmentLine."No.");
    end;

    var
        OpenWorkMgt: Codeunit "WHA Open Work Mgt.";
}
