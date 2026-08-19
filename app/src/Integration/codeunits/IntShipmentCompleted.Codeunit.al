namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.DirectedWork;

codeunit 50669 "WHA Int. Shipment Completed" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        OutboundOnlyErr: Label 'A completed shipment is only ever reported to the partner system, so message %1 cannot be applied here.', Comment = '%1 = the message entry number';

    /// <summary>
    /// Rejects the message. What a shipment did is something this app reports, not something it accepts.
    /// </summary>
    /// <param name="IntegrationMessage">The message that cannot be applied.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    begin
        Error(OutboundOnlyErr, IntegrationMessage."Entry No.");
    end;

    /// <summary>
    /// Reports every warehouse shipment whose pick work is finished, on the same rule the receipt side
    /// uses: the shipment has work against it and none of that work is still open. A short pick that was
    /// completed short still counts as finished, because nobody is going to pick it now — what was short
    /// is on the task confirmation, not here.
    /// </summary>
    procedure CollectOutbound()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        SourceType: Enum "WHA Task Source";
        MessageType: Enum "WHA Int. Message Type";
        ReportedNo: Code[20];
    begin
        WarehouseTask.SetCurrentKey("Source Type", "Source No.", "Source Line No.");
        WarehouseTask.SetRange("Source Type", SourceType::WHAWhseShipment);
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHACompleted);
        if not WarehouseTask.FindSet() then
            exit;

        ReportedNo := '';
        repeat
            if WarehouseTask."Source No." <> ReportedNo then begin
                ReportedNo := WarehouseTask."Source No.";
                if not MessageMgt.HasOutbound(MessageType::WHAWarehouseShipmentDone, ReportedNo) then
                    if not HasOpenWork(SourceType::WHAWhseShipment, ReportedNo) then
                        MessageMgt.CreateOutbound(
                            MessageType::WHAWarehouseShipmentDone,
                            ReportedNo,
                            BuildPayload(SourceType::WHAWhseShipment, ReportedNo, MessageMgt),
                            WarehouseTask.RecordId());
            end;
        until WarehouseTask.Next() = 0;
    end;

    local procedure HasOpenWork(SourceType: Enum "WHA Task Source"; SourceNo: Code[20]): Boolean
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetCurrentKey("Source Type", "Source No.", "Source Line No.");
        WarehouseTask.SetRange("Source Type", SourceType);
        WarehouseTask.SetRange("Source No.", SourceNo);
        WarehouseTask.SetFilter(Status, '<>%1&<>%2', WarehouseTask.Status::WHACompleted, WarehouseTask.Status::WHACancelled);
        exit(not WarehouseTask.IsEmpty());
    end;

    local procedure BuildPayload(SourceType: Enum "WHA Task Source"; SourceNo: Code[20]; var MessageMgt: Codeunit "WHA Int. Message Mgt."): Text
    var
        WarehouseTask: Record "WHA Warehouse Task";
        PayloadObject: JsonObject;
        PayloadText: Text;
        Completed: Integer;
        Handled: Decimal;
        Short: Decimal;
        LastCompletedAt: DateTime;
    begin
        WarehouseTask.SetCurrentKey("Source Type", "Source No.", "Source Line No.");
        WarehouseTask.SetRange("Source Type", SourceType);
        WarehouseTask.SetRange("Source No.", SourceNo);
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHACompleted);
        LastCompletedAt := 0DT;
        if WarehouseTask.FindSet() then
            repeat
                Completed += 1;
                Handled += WarehouseTask."Quantity Handled";
                Short += WarehouseTask.Quantity - WarehouseTask."Quantity Handled";
                if WarehouseTask."Completed At" > LastCompletedAt then
                    LastCompletedAt := WarehouseTask."Completed At";
            until WarehouseTask.Next() = 0;

        PayloadObject.Add('warehouseShipmentNumber', SourceNo);
        PayloadObject.Add('tasksCompleted', Completed);
        PayloadObject.Add('quantityHandled', Handled);
        PayloadObject.Add('quantityShort', Short);
        PayloadObject.Add('completedDateTime', MessageMgt.IsoDateTime(LastCompletedAt));
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;
}
