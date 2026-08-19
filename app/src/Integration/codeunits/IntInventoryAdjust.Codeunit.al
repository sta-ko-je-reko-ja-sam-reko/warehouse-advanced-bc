namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Posting;

codeunit 50666 "WHA Int. Inventory Adjust" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        NoPayloadErr: Label 'Message %1 has no readable JSON body, so there is nothing to adjust.', Comment = '%1 = the message entry number';
        DuplicateErr: Label 'An adjustment has already been made for external ID %1. Adjusting twice would double the correction.', Comment = '%1 = the external identifier the partner system sent';
        ItemMissingErr: Label 'Message %1 does not say which item to adjust.', Comment = '%1 = the message entry number';
        LocationMissingErr: Label 'Message %1 does not say where the adjustment happens.', Comment = '%1 = the message entry number';
        ZeroQuantityErr: Label 'Message %1 asks for an adjustment of nothing. A correction of zero changes no stock and is refused rather than recorded.', Comment = '%1 = the message entry number';
        NotTakenErr: Label 'The posting method configured for the integration surface took no line for message %1.', Comment = '%1 = the message entry number';
        LineDescriptionLbl: Label 'Adjustment from %1', Comment = '%1 = the partner system that sent the adjustment';

    /// <summary>
    /// Turns a stock correction from the partner system into an inventory adjustment, through the same
    /// shared posting engine counting and quality hold use. What actually happens to the ledger is the
    /// posting method in the integration setup, not this codeunit: it may record nothing, write a journal
    /// line for somebody to look at, or post straight through.
    /// </summary>
    /// <param name="IntegrationMessage">The adjustment to apply.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    var
        Setup: Record "WHA Integration Setup";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        PostingMgt: Codeunit "WHA Posting Mgt.";
        PayloadObject: JsonObject;
    begin
        if not MessageMgt.TryReadPayload(IntegrationMessage, PayloadObject) then
            Error(NoPayloadErr, IntegrationMessage."Entry No.");

        if MessageMgt.HasProcessedInbound(IntegrationMessage."Message Type", IntegrationMessage."External Id", IntegrationMessage."Entry No.") then
            Error(DuplicateErr, IntegrationMessage."External Id");

        ReadSetup(Setup);
        BuildRequest(TempPostingRequest, IntegrationMessage, PayloadObject, MessageMgt, Setup);

        if PostingMgt.Post(Setup."Posting Method", TempPostingRequest) = 0 then
            Error(NotTakenErr, IntegrationMessage."Entry No.");

        TempPostingRequest.Reset();
        if TempPostingRequest.FindFirst() then
            IntegrationMessage."Record ID" := TempPostingRequest.RecordId();
        IntegrationMessage.Modify(true);
    end;

    /// <summary>
    /// Collects nothing. A correction sent by the partner system is only ever received; what this
    /// warehouse itself counted goes back as a count result.
    /// </summary>
    procedure CollectOutbound()
    begin
    end;

    local procedure BuildRequest(var PostingRequest: Record "WHA Posting Request"; var IntegrationMessage: Record "WHA Integration Message"; PayloadObject: JsonObject; var MessageMgt: Codeunit "WHA Int. Message Mgt."; var Setup: Record "WHA Integration Setup")
    var
        PostingType: Enum "WHA Posting Type";
        ItemNo: Code[20];
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        ItemNo := CopyStr(MessageMgt.JsonText(PayloadObject, 'itemNumber'), 1, MaxStrLen(PostingRequest."Item No."));
        if ItemNo = '' then
            Error(ItemMissingErr, IntegrationMessage."Entry No.");

        LocationCode := CopyStr(MessageMgt.JsonText(PayloadObject, 'locationCode'), 1, MaxStrLen(PostingRequest."Location Code"));
        if LocationCode = '' then
            Error(LocationMissingErr, IntegrationMessage."Entry No.");

        Quantity := MessageMgt.JsonDecimal(PayloadObject, 'quantity');
        if Quantity = 0 then
            Error(ZeroQuantityErr, IntegrationMessage."Entry No.");

        if Quantity < 0 then
            PostingType := PostingType::WHANegativeAdjustment
        else
            PostingType := PostingType::WHAPositiveAdjustment;

        PostingRequest.Init();
        PostingRequest."Entry No." := 1;
        PostingRequest."Posting Type" := PostingType;
        PostingRequest."Item No." := ItemNo;
        PostingRequest."Variant Code" := CopyStr(MessageMgt.JsonText(PayloadObject, 'variantCode'), 1, MaxStrLen(PostingRequest."Variant Code"));
        PostingRequest."Unit of Measure Code" := CopyStr(MessageMgt.JsonText(PayloadObject, 'unitOfMeasureCode'), 1, MaxStrLen(PostingRequest."Unit of Measure Code"));
        PostingRequest.Quantity := Abs(Quantity);
        PostingRequest."Location Code" := LocationCode;
        PostingRequest."Bin Code" := CopyStr(MessageMgt.JsonText(PayloadObject, 'binCode'), 1, MaxStrLen(PostingRequest."Bin Code"));
        PostingRequest."Lot No." := CopyStr(MessageMgt.JsonText(PayloadObject, 'lotNumber'), 1, MaxStrLen(PostingRequest."Lot No."));
        PostingRequest."Serial No." := CopyStr(MessageMgt.JsonText(PayloadObject, 'serialNumber'), 1, MaxStrLen(PostingRequest."Serial No."));
        PostingRequest."Posting Date" := WorkDate();
        PostingRequest."Document No." := CopyStr(IntegrationMessage."External Id", 1, MaxStrLen(PostingRequest."Document No."));
        PostingRequest.Description := CopyStr(StrSubstNo(LineDescriptionLbl, IntegrationMessage."Partner System"), 1, MaxStrLen(PostingRequest.Description));
        PostingRequest."Reason Code" := Setup."Posting Reason Code";
        PostingRequest."Journal Template Name" := Setup."Item Journal Template Name";
        PostingRequest."Journal Batch Name" := Setup."Item Journal Batch Name";
        PostingRequest."Source Table No." := Database::"WHA Integration Message";
        PostingRequest."Source No." := CopyStr(IntegrationMessage."External Id", 1, MaxStrLen(PostingRequest."Source No."));
        PostingRequest."Source Line No." := IntegrationMessage."Entry No.";
        PostingRequest.Insert(false);
    end;

    local procedure ReadSetup(var Setup: Record "WHA Integration Setup")
    begin
        Setup.SetLoadFields("Posting Method", "Item Journal Template Name", "Item Journal Batch Name", "Posting Reason Code");
        if Setup.Get() then
            exit;
        Setup.Init();
    end;
}
