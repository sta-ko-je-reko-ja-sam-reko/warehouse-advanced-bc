namespace WarehouseAdvanced.Integration;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.IO;

codeunit 50659 "WHA Demo Integration"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-INT', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Integration';
        ReceiptExternalIdTok: Label 'DEMO-INT-RECEIPT-001', Locked = true;
        RequestExternalIdTok: Label 'DEMO-INT-REQUEST-001', Locked = true;
        RejectedExternalIdTok: Label 'DEMO-INT-REQUEST-002', Locked = true;
        CancelledExternalIdTok: Label 'DEMO-INT-REQUEST-003', Locked = true;
        ConfirmExternalIdTok: Label 'DEMO-INT-CONFIRM-001', Locked = true;
        ReceiptDescLbl: Label 'Pallet from the partner system';
        RequestDescLbl: Label 'Pick requested by the partner system';
        CancelledDescLbl: Label 'Move requested, then withdrawn by the partner system';

    /// <summary>
    /// Seeds sample integration messages that show both directions, every status a message can reach,
    /// a readable payload, and a failure with its error text. Idempotent — re-running creates nothing
    /// new. Also builds this feature's RapidStart configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Integration Setup";
        IntFeatureSetup: Codeunit "WHA Int. Feature Setup";
    begin
        IntFeatureSetup.EnsureSetup(Setup);

        CreateReceiptMessage();
        CreateRequestMessage();
        CreateRejectedMessage();
        CreateCancelledMessage();
        CreateOutboundMessage();

        CreateConfigPackage();
    end;

    local procedure CreateReceiptMessage()
    var
        MessageType: Enum "WHA Int. Message Type";
    begin
        InsertInbound(MessageType::WHAHandlingUnitReceived, CopyStr(ReceiptExternalIdTok, 1, 50), ReceiptPayload());
    end;

    local procedure CreateRequestMessage()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        EntryNo := InsertInbound(MessageType::WHAWarehouseTaskRequest, CopyStr(RequestExternalIdTok, 1, 50), RequestPayload());
        if EntryNo = 0 then
            exit;
        if not IntegrationMessage.Get(EntryNo) then
            exit;
        if IntegrationMessage.Status <> IntegrationMessage.Status::WHANew then
            exit;

        MessageMgt.Process(IntegrationMessage);
    end;

    local procedure CreateCancelledMessage()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        EntryNo := InsertInbound(MessageType::WHAWarehouseTaskRequest, CopyStr(CancelledExternalIdTok, 1, 50), CancelledPayload());
        if EntryNo = 0 then
            exit;
        if not IntegrationMessage.Get(EntryNo) then
            exit;
        if IntegrationMessage.Status <> IntegrationMessage.Status::WHANew then
            exit;

        MessageMgt.Cancel(IntegrationMessage);
    end;

    local procedure CreateRejectedMessage()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        if MessageExists(MessageType::WHAWarehouseTaskRequest, CopyStr(RejectedExternalIdTok, 1, 50)) then
            exit;

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, CopyStr(RejectedExternalIdTok, 1, 50), '', '{"taskType":"WHAPick"}');
        if not IntegrationMessage.Get(EntryNo) then
            exit;
        if IntegrationMessage.Status <> IntegrationMessage.Status::WHANew then
            exit;

        MessageMgt.Process(IntegrationMessage);
    end;

    local procedure CreateOutboundMessage()
    var
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        EmptyRecordId: RecordId;
        MessageType: Enum "WHA Int. Message Type";
    begin
        if MessageExists(MessageType::WHAWarehouseTaskConfirmed, CopyStr(ConfirmExternalIdTok, 1, 50)) then
            exit;

        MessageMgt.CreateOutbound(MessageType::WHAWarehouseTaskConfirmed, CopyStr(ConfirmExternalIdTok, 1, 50), ConfirmPayload(), EmptyRecordId);
    end;

    local procedure InsertInbound(MessageType: Enum "WHA Int. Message Type"; ExternalId: Code[50]; PayloadText: Text): Integer
    var
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
    begin
        if MessageExists(MessageType, ExternalId) then
            exit(0);

        exit(MessageMgt.CreateInbound(MessageType, ExternalId, '', PayloadText));
    end;

    local procedure MessageExists(MessageType: Enum "WHA Int. Message Type"; ExternalId: Code[50]): Boolean
    var
        IntegrationMessage: Record "WHA Integration Message";
    begin
        IntegrationMessage.SetLoadFields("Entry No.");
        IntegrationMessage.SetCurrentKey("Message Type", "External Id");
        IntegrationMessage.SetRange("Message Type", MessageType);
        IntegrationMessage.SetRange("External Id", ExternalId);
        exit(not IntegrationMessage.IsEmpty());
    end;

    local procedure ReceiptPayload(): Text
    var
        PayloadObject: JsonObject;
        LineArray: JsonArray;
        PayloadText: Text;
    begin
        PayloadObject.Add('externalId', ReceiptExternalIdTok);
        PayloadObject.Add('sscc', '380123456789012364');
        PayloadObject.Add('description', ReceiptDescLbl);
        PayloadObject.Add('locationCode', FirstLocation());
        PayloadObject.Add('binCode', '');

        LineArray.Add(SampleLine(FirstItem(), 8));
        PayloadObject.Add('lines', LineArray);

        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure SampleLine(ItemNo: Code[20]; Qty: Decimal): JsonObject
    var
        LineObject: JsonObject;
    begin
        LineObject.Add('itemNumber', ItemNo);
        LineObject.Add('variantCode', '');
        LineObject.Add('quantity', Qty);
        LineObject.Add('lotNumber', '');
        LineObject.Add('serialNumber', '');
        exit(LineObject);
    end;

    local procedure RequestPayload(): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('externalId', RequestExternalIdTok);
        PayloadObject.Add('taskType', 'WHAPick');
        PayloadObject.Add('description', RequestDescLbl);
        PayloadObject.Add('locationCode', FirstLocation());
        PayloadObject.Add('itemNumber', FirstItem());
        PayloadObject.Add('quantity', 4);
        PayloadObject.Add('priority', 10);
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure CancelledPayload(): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('externalId', CancelledExternalIdTok);
        PayloadObject.Add('taskType', 'WHAMovement');
        PayloadObject.Add('description', CancelledDescLbl);
        PayloadObject.Add('locationCode', FirstLocation());
        PayloadObject.Add('itemNumber', FirstItem());
        PayloadObject.Add('quantity', 2);
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure ConfirmPayload(): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('number', 'WT000001');
        PayloadObject.Add('taskType', 'WHAPick');
        PayloadObject.Add('status', 'WHACompleted');
        PayloadObject.Add('locationCode', FirstLocation());
        PayloadObject.Add('quantity', 4);
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure FirstLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetLoadFields(Code);
        Location.SetRange("Use As In-Transit", false);
        if not Location.FindFirst() then
            exit('');
        exit(Location.Code);
    end;

    local procedure FirstItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("No.");
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetRange(Blocked, false);
        if not Item.FindFirst() then
            exit('');
        exit(Item."No.");
    end;

    local procedure CreateConfigPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        if ConfigPackage.Get(PackageCodeTok) then
            exit;

        ConfigPackageMgt.InsertPackage(ConfigPackage, PackageCodeTok, CopyStr(PackageNameLbl, 1, 50), true);
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Integration Message");
    end;
}
