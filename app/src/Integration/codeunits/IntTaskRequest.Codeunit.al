namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.DirectedWork;

codeunit 50655 "WHA Int. Task Request" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        NoPayloadErr: Label 'Message %1 has no readable JSON body, so there is nothing to create a warehouse task from.', Comment = '%1 = the message entry number';
        DuplicateErr: Label 'A warehouse task has already been created for external ID %1. The partner system should send a new identifier for new work.', Comment = '%1 = the external identifier the partner system sent';
        UnknownTaskTypeErr: Label 'The partner system asked for task type %1, which this app does not have.', Comment = '%1 = the task type name that arrived in the message';
        NothingToDoErr: Label 'Message %1 names neither a handling unit nor an item, so there is no work to do.', Comment = '%1 = the message entry number';

    /// <summary>
    /// Creates a warehouse task from the request and releases it, so the work reaches the floor. An
    /// incomplete request fails the message rather than leaving a half-built task behind.
    /// </summary>
    /// <param name="IntegrationMessage">The request to apply.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    var
        WarehouseTask: Record "WHA Warehouse Task";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        PayloadObject: JsonObject;
    begin
        if not MessageMgt.TryReadPayload(IntegrationMessage, PayloadObject) then
            Error(NoPayloadErr, IntegrationMessage."Entry No.");

        if MessageMgt.HasProcessedInbound(IntegrationMessage."Message Type", IntegrationMessage."External Id", IntegrationMessage."Entry No.") then
            Error(DuplicateErr, IntegrationMessage."External Id");

        BuildTask(WarehouseTask, PayloadObject, MessageMgt, IntegrationMessage."Entry No.");
        WarehouseTask.Insert(true);

        if WarehouseTask.Status = WarehouseTask.Status::WHACreated then
            TaskLogic.Release(WarehouseTask);

        IntegrationMessage."Record ID" := WarehouseTask.RecordId();
        IntegrationMessage.Modify(true);
    end;

    /// <summary>
    /// Collects nothing. A request for work is only ever received.
    /// </summary>
    procedure CollectOutbound()
    begin
    end;

    local procedure BuildTask(var WarehouseTask: Record "WHA Warehouse Task"; PayloadObject: JsonObject; var MessageMgt: Codeunit "WHA Int. Message Mgt."; EntryNo: Integer)
    var
        HandlingUnitNo: Code[20];
        ItemNo: Code[20];
    begin
        WarehouseTask.Init();
        WarehouseTask.Validate("Task Type", TaskTypeFromName(MessageMgt.JsonText(PayloadObject, 'taskType')));
        WarehouseTask.Validate(Description, CopyStr(MessageMgt.JsonText(PayloadObject, 'description'), 1, MaxStrLen(WarehouseTask.Description)));

        WarehouseTask.Validate("Location Code", CopyStr(MessageMgt.JsonText(PayloadObject, 'locationCode'), 1, MaxStrLen(WarehouseTask."Location Code")));

        HandlingUnitNo := CopyStr(MessageMgt.JsonText(PayloadObject, 'handlingUnitNumber'), 1, MaxStrLen(WarehouseTask."Handling Unit No."));
        ItemNo := CopyStr(MessageMgt.JsonText(PayloadObject, 'itemNumber'), 1, MaxStrLen(WarehouseTask."Item No."));
        if (HandlingUnitNo = '') and (ItemNo = '') then
            Error(NothingToDoErr, EntryNo);

        if HandlingUnitNo <> '' then
            WarehouseTask.Validate("Handling Unit No.", HandlingUnitNo);

        if ItemNo <> '' then begin
            WarehouseTask.Validate("Item No.", ItemNo);
            WarehouseTask.Validate("Variant Code", CopyStr(MessageMgt.JsonText(PayloadObject, 'variantCode'), 1, MaxStrLen(WarehouseTask."Variant Code")));
            WarehouseTask.Validate(Quantity, MessageMgt.JsonDecimal(PayloadObject, 'quantity'));
        end;

        ApplyBins(WarehouseTask, PayloadObject, MessageMgt);

        if MessageMgt.JsonText(PayloadObject, 'priority') <> '' then
            WarehouseTask.Validate(Priority, MessageMgt.JsonInteger(PayloadObject, 'priority'));
        WarehouseTask.Validate("Due Date", MessageMgt.JsonDate(PayloadObject, 'dueDate'));
    end;

    local procedure ApplyBins(var WarehouseTask: Record "WHA Warehouse Task"; PayloadObject: JsonObject; var MessageMgt: Codeunit "WHA Int. Message Mgt.")
    var
        FromBinCode: Code[20];
        ToBinCode: Code[20];
    begin
        FromBinCode := CopyStr(MessageMgt.JsonText(PayloadObject, 'fromBinCode'), 1, MaxStrLen(WarehouseTask."From Bin Code"));
        ToBinCode := CopyStr(MessageMgt.JsonText(PayloadObject, 'toBinCode'), 1, MaxStrLen(WarehouseTask."To Bin Code"));

        if FromBinCode <> '' then
            WarehouseTask.Validate("From Bin Code", FromBinCode);
        if ToBinCode <> '' then
            WarehouseTask.Validate("To Bin Code", ToBinCode);
    end;

    local procedure TaskTypeFromName(TypeName: Text): Enum "WHA Warehouse Task Type"
    var
        TaskType: Enum "WHA Warehouse Task Type";
        Ordinal: Integer;
    begin
        if TypeName = '' then
            exit(TaskType::WHAMovement);

        foreach Ordinal in Enum::"WHA Warehouse Task Type".Ordinals() do begin
            TaskType := Enum::"WHA Warehouse Task Type".FromInteger(Ordinal);
            if Format(TaskType, 0, 9) = TypeName then
                exit(TaskType);
        end;

        Error(UnknownTaskTypeErr, TypeName);
    end;
}
