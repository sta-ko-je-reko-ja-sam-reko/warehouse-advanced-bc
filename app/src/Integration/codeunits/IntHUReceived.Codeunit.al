namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.HandlingUnit;

codeunit 50657 "WHA Int. HU Received" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        NoPayloadErr: Label 'Message %1 has no readable JSON body, so there is nothing to create a handling unit from.', Comment = '%1 = the message entry number';
        DuplicateErr: Label 'A handling unit has already been created for external ID %1. The partner system should send a new identifier for a new unit.', Comment = '%1 = the external identifier the partner system sent';

    /// <summary>
    /// Creates a handling unit, and a content line for each item the partner system says is on it. The
    /// unit takes its number from the app's own number series — the partner's identifier is kept on the
    /// message, not on the unit.
    /// </summary>
    /// <param name="IntegrationMessage">The notification to apply.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    var
        HandlingUnit: Record "WHA Handling Unit";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        PayloadObject: JsonObject;
    begin
        if not MessageMgt.TryReadPayload(IntegrationMessage, PayloadObject) then
            Error(NoPayloadErr, IntegrationMessage."Entry No.");

        if MessageMgt.HasProcessedInbound(IntegrationMessage."Message Type", IntegrationMessage."External Id", IntegrationMessage."Entry No.") then
            Error(DuplicateErr, IntegrationMessage."External Id");

        CreateUnit(HandlingUnit, PayloadObject, MessageMgt);
        CreateLines(HandlingUnit, PayloadObject, MessageMgt);

        IntegrationMessage."Record ID" := HandlingUnit.RecordId();
        IntegrationMessage.Modify(true);
    end;

    /// <summary>
    /// Collects nothing. A receipt notification is only ever received.
    /// </summary>
    procedure CollectOutbound()
    begin
    end;

    local procedure CreateUnit(var HandlingUnit: Record "WHA Handling Unit"; PayloadObject: JsonObject; var MessageMgt: Codeunit "WHA Int. Message Mgt.")
    var
        BinCode: Code[20];
    begin
        HandlingUnit.Init();
        HandlingUnit.Validate(SSCC, CopyStr(MessageMgt.JsonText(PayloadObject, 'sscc'), 1, MaxStrLen(HandlingUnit.SSCC)));
        HandlingUnit.Validate(Description, CopyStr(MessageMgt.JsonText(PayloadObject, 'description'), 1, MaxStrLen(HandlingUnit.Description)));
        HandlingUnit.Validate("Location Code", CopyStr(MessageMgt.JsonText(PayloadObject, 'locationCode'), 1, MaxStrLen(HandlingUnit."Location Code")));

        BinCode := CopyStr(MessageMgt.JsonText(PayloadObject, 'binCode'), 1, MaxStrLen(HandlingUnit."Bin Code"));
        if BinCode <> '' then
            HandlingUnit.Validate("Bin Code", BinCode);

        HandlingUnit.Insert(true);
    end;

    local procedure CreateLines(var HandlingUnit: Record "WHA Handling Unit"; PayloadObject: JsonObject; var MessageMgt: Codeunit "WHA Int. Message Mgt.")
    var
        LineArray: JsonArray;
        LineToken: JsonToken;
    begin
        if not MessageMgt.JsonArray(PayloadObject, 'lines', LineArray) then
            exit;

        foreach LineToken in LineArray do
            if LineToken.IsObject() then
                CreateLine(HandlingUnit, LineToken.AsObject(), MessageMgt);
    end;

    local procedure CreateLine(var HandlingUnit: Record "WHA Handling Unit"; LineObject: JsonObject; var MessageMgt: Codeunit "WHA Int. Message Mgt.")
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        ItemNo: Code[20];
        VariantCode: Code[10];
        LotNo: Code[50];
        SerialNo: Code[50];
    begin
        ItemNo := CopyStr(MessageMgt.JsonText(LineObject, 'itemNumber'), 1, MaxStrLen(HandlingUnitLine."Item No."));
        if ItemNo = '' then
            exit;

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := HandlingUnit."No.";
        HandlingUnitLine.Validate("Item No.", ItemNo);

        VariantCode := CopyStr(MessageMgt.JsonText(LineObject, 'variantCode'), 1, MaxStrLen(HandlingUnitLine."Variant Code"));
        if VariantCode <> '' then
            HandlingUnitLine.Validate("Variant Code", VariantCode);

        LotNo := CopyStr(MessageMgt.JsonText(LineObject, 'lotNumber'), 1, MaxStrLen(HandlingUnitLine."Lot No."));
        if LotNo <> '' then
            HandlingUnitLine.Validate("Lot No.", LotNo);

        SerialNo := CopyStr(MessageMgt.JsonText(LineObject, 'serialNumber'), 1, MaxStrLen(HandlingUnitLine."Serial No."));
        if SerialNo <> '' then
            HandlingUnitLine.Validate("Serial No.", SerialNo);

        HandlingUnitLine.Validate(Quantity, MessageMgt.JsonDecimal(LineObject, 'quantity'));
        HandlingUnitLine.Insert(true);
    end;
}
