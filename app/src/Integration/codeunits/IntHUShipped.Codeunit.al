namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.HandlingUnit;

codeunit 50658 "WHA Int. HU Shipped" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        OutboundOnlyErr: Label 'A despatch notification is only ever sent to the partner system, so message %1 cannot be applied here.', Comment = '%1 = the message entry number';

    /// <summary>
    /// Rejects the message. A despatch notification is something this app sends, not something it
    /// accepts.
    /// </summary>
    /// <param name="IntegrationMessage">The message that cannot be applied.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    begin
        Error(OutboundOnlyErr, IntegrationMessage."Entry No.");
    end;

    /// <summary>
    /// Puts a despatch notification in the outbox for every handling unit that has shipped and has not
    /// been reported yet, with the contents of the unit as it left.
    /// </summary>
    procedure CollectOutbound()
    var
        HandlingUnit: Record "WHA Handling Unit";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        HandlingUnit.SetRange(Status, HandlingUnit.Status::WHAShipped);
        if not HandlingUnit.FindSet() then
            exit;

        repeat
            if not MessageMgt.HasOutbound(MessageType::WHAHandlingUnitShipped, HandlingUnit."No.") then
                MessageMgt.CreateOutbound(
                    MessageType::WHAHandlingUnitShipped,
                    HandlingUnit."No.",
                    BuildPayload(HandlingUnit),
                    HandlingUnit.RecordId());
        until HandlingUnit.Next() = 0;
    end;

    local procedure BuildPayload(var HandlingUnit: Record "WHA Handling Unit"): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('number', HandlingUnit."No.");
        PayloadObject.Add('sscc', HandlingUnit.SSCC);
        PayloadObject.Add('description', HandlingUnit.Description);
        PayloadObject.Add('locationCode', HandlingUnit."Location Code");
        PayloadObject.Add('binCode', HandlingUnit."Bin Code");
        PayloadObject.Add('parentNumber', HandlingUnit."Parent No.");
        PayloadObject.Add('status', Format(HandlingUnit.Status, 0, 9));
        PayloadObject.Add('lines', BuildLines(HandlingUnit));
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure BuildLines(var HandlingUnit: Record "WHA Handling Unit"): JsonArray
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        LineArray: JsonArray;
    begin
        HandlingUnitLine.SetRange("Handling Unit No.", HandlingUnit."No.");
        if not HandlingUnitLine.FindSet() then
            exit(LineArray);

        repeat
            LineArray.Add(BuildLine(HandlingUnitLine));
        until HandlingUnitLine.Next() = 0;

        exit(LineArray);
    end;

    local procedure BuildLine(var HandlingUnitLine: Record "WHA Handling Unit Line"): JsonObject
    var
        LineObject: JsonObject;
    begin
        LineObject.Add('lineNumber', HandlingUnitLine."Line No.");
        LineObject.Add('itemNumber', HandlingUnitLine."Item No.");
        LineObject.Add('variantCode', HandlingUnitLine."Variant Code");
        LineObject.Add('description', HandlingUnitLine.Description);
        LineObject.Add('quantity', HandlingUnitLine.Quantity);
        LineObject.Add('unitOfMeasureCode', HandlingUnitLine."Unit of Measure Code");
        LineObject.Add('lotNumber', HandlingUnitLine."Lot No.");
        LineObject.Add('serialNumber', HandlingUnitLine."Serial No.");
        exit(LineObject);
    end;
}
