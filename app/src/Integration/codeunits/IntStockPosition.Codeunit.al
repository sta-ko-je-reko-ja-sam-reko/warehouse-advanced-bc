namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.HandlingUnit;

codeunit 50671 "WHA Int. Stock Position" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        OutboundOnlyErr: Label 'A stock position is only ever reported to the partner system, so message %1 cannot be applied here.', Comment = '%1 = the message entry number';
        StatementIdTok: Label '%1|%2', Locked = true;

    /// <summary>
    /// Rejects the message. A statement of what is here is something this app produces; what the partner
    /// system believes is here arrives as an inventory adjustment instead.
    /// </summary>
    /// <param name="IntegrationMessage">The message that cannot be applied.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    begin
        Error(OutboundOnlyErr, IntegrationMessage."Entry No.");
    end;

    /// <summary>
    /// Puts one stock statement per location in the outbox, once per working day. The statement counts
    /// **what this app has recorded on handling units** and nothing else — it is not a reading of the
    /// item ledger, and a warehouse holding stock this app never put on a unit will find the two
    /// disagree. That disagreement is the point of sending it.
    /// </summary>
    procedure CollectOutbound()
    var
        HandlingUnit: Record "WHA Handling Unit";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        ReportedLocation: Code[10];
        StatementId: Code[50];
    begin
        HandlingUnit.SetCurrentKey("Location Code", "Bin Code");
        HandlingUnit.SetFilter("Location Code", '<>%1', '');
        if not HandlingUnit.FindSet() then
            exit;

        ReportedLocation := '';
        repeat
            if HandlingUnit."Location Code" <> ReportedLocation then begin
                ReportedLocation := HandlingUnit."Location Code";
                StatementId := StatementIdOf(ReportedLocation);
                if not MessageMgt.HasOutbound(MessageType::WHAStockPosition, StatementId) then
                    MessageMgt.CreateOutbound(
                        MessageType::WHAStockPosition,
                        StatementId,
                        BuildPayload(ReportedLocation),
                        HandlingUnit.RecordId());
            end;
        until HandlingUnit.Next() = 0;
    end;

    local procedure StatementIdOf(LocationCode: Code[10]): Code[50]
    begin
        exit(CopyStr(StrSubstNo(StatementIdTok, LocationCode, Format(WorkDate(), 0, '<Year4><Month,2><Day,2>')), 1, 50));
    end;

    local procedure BuildPayload(LocationCode: Code[10]): Text
    var
        StockByLocation: Query "WHA HU Stock By Location";
        PayloadObject: JsonObject;
        LineArray: JsonArray;
        PayloadText: Text;
        TotalQuantity: Decimal;
    begin
        StockByLocation.SetRange(locationCode, LocationCode);
        StockByLocation.Open();
        while StockByLocation.Read() do begin
            LineArray.Add(BuildLine(StockByLocation));
            TotalQuantity += StockByLocation.quantity;
        end;
        StockByLocation.Close();

        PayloadObject.Add('locationCode', LocationCode);
        PayloadObject.Add('statementDate', Format(WorkDate(), 0, 9));
        PayloadObject.Add('totalQuantity', TotalQuantity);
        PayloadObject.Add('lines', LineArray);
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure BuildLine(var StockByLocation: Query "WHA HU Stock By Location"): JsonObject
    var
        LineObject: JsonObject;
    begin
        LineObject.Add('itemNumber', StockByLocation.itemNo);
        LineObject.Add('variantCode', StockByLocation.variantCode);
        LineObject.Add('unitOfMeasureCode', StockByLocation.unitOfMeasureCode);
        LineObject.Add('quantity', StockByLocation.quantity);
        exit(LineObject);
    end;
}
