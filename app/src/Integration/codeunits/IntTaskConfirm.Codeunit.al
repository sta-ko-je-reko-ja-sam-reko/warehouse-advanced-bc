namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.DirectedWork;

codeunit 50656 "WHA Int. Task Confirm" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        OutboundOnlyErr: Label 'A warehouse task confirmation is only ever sent to the partner system, so message %1 cannot be applied here.', Comment = '%1 = the message entry number';

    /// <summary>
    /// Rejects the message. A confirmation is something this app sends, not something it accepts.
    /// </summary>
    /// <param name="IntegrationMessage">The message that cannot be applied.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    begin
        Error(OutboundOnlyErr, IntegrationMessage."Entry No.");
    end;

    /// <summary>
    /// Puts a confirmation in the outbox for every completed warehouse task the partner system has not
    /// been told about. The outbox itself is the record of what has been sent, so no flag is kept on the
    /// task.
    /// </summary>
    procedure CollectOutbound()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        WarehouseTask.SetCurrentKey(Status, "Location Code", Priority, "Due Date");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHACompleted);
        if not WarehouseTask.FindSet() then
            exit;

        repeat
            if not MessageMgt.HasOutbound(MessageType::WHAWarehouseTaskConfirmed, WarehouseTask."No.") then
                MessageMgt.CreateOutbound(
                    MessageType::WHAWarehouseTaskConfirmed,
                    WarehouseTask."No.",
                    BuildPayload(WarehouseTask, MessageMgt),
                    WarehouseTask.RecordId());
        until WarehouseTask.Next() = 0;
    end;

    local procedure BuildPayload(var WarehouseTask: Record "WHA Warehouse Task"; var MessageMgt: Codeunit "WHA Int. Message Mgt."): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('number', WarehouseTask."No.");
        PayloadObject.Add('taskType', Format(WarehouseTask."Task Type", 0, 9));
        PayloadObject.Add('status', Format(WarehouseTask.Status, 0, 9));
        PayloadObject.Add('description', WarehouseTask.Description);
        PayloadObject.Add('locationCode', WarehouseTask."Location Code");
        PayloadObject.Add('fromBinCode', WarehouseTask."From Bin Code");
        PayloadObject.Add('toBinCode', WarehouseTask."To Bin Code");
        PayloadObject.Add('handlingUnitNumber', WarehouseTask."Handling Unit No.");
        PayloadObject.Add('itemNumber', WarehouseTask."Item No.");
        PayloadObject.Add('variantCode', WarehouseTask."Variant Code");
        PayloadObject.Add('quantity', WarehouseTask.Quantity);
        PayloadObject.Add('quantityHandled', WarehouseTask."Quantity Handled");
        PayloadObject.Add('quantityOutstanding', WarehouseTask.Quantity - WarehouseTask."Quantity Handled");
        PayloadObject.Add('shortReason', Format(WarehouseTask."Short Reason", 0, 9));
        PayloadObject.Add('unitOfMeasureCode', WarehouseTask."Unit of Measure Code");
        PayloadObject.Add('assignedToUserId', WarehouseTask."Assigned To User ID");
        PayloadObject.Add('startedDateTime', MessageMgt.IsoDateTime(WarehouseTask."Started At"));
        PayloadObject.Add('completedDateTime', MessageMgt.IsoDateTime(WarehouseTask."Completed At"));
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;
}
