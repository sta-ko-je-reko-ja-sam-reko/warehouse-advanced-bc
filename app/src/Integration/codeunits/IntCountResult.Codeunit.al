namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Counting;

codeunit 50670 "WHA Int. Count Result" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        OutboundOnlyErr: Label 'A count result is only ever reported to the partner system, so message %1 cannot be applied here.', Comment = '%1 = the message entry number';

    /// <summary>
    /// Rejects the message. What a count found is something this app reports; a correction arriving from
    /// the other direction is an inventory adjustment, which is a different message type on purpose.
    /// </summary>
    /// <param name="IntegrationMessage">The message that cannot be applied.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    begin
        Error(OutboundOnlyErr, IntegrationMessage."Entry No.");
    end;

    /// <summary>
    /// Reports every closed count sheet. A sheet is reported when it closes rather than when it is
    /// counted, because closing is the moment a difference stops being an observation, and reporting one
    /// that somebody may still reject would tell the partner system something untrue.
    /// </summary>
    procedure CollectOutbound()
    var
        CountSheet: Record "WHA Count Sheet";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        CountSheet.SetCurrentKey("Location Code", Status);
        CountSheet.SetRange(Status, CountSheet.Status::WHAClosed);
        if not CountSheet.FindSet() then
            exit;

        repeat
            if not MessageMgt.HasOutbound(MessageType::WHACountResult, CountSheet."No.") then
                MessageMgt.CreateOutbound(
                    MessageType::WHACountResult,
                    CountSheet."No.",
                    BuildPayload(CountSheet, MessageMgt),
                    CountSheet.RecordId());
        until CountSheet.Next() = 0;
    end;

    local procedure BuildPayload(var CountSheet: Record "WHA Count Sheet"; var MessageMgt: Codeunit "WHA Int. Message Mgt."): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('countSheetNumber', CountSheet."No.");
        PayloadObject.Add('locationCode', CountSheet."Location Code");
        PayloadObject.Add('postingDate', Format(CountSheet."Posting Date", 0, 9));
        PayloadObject.Add('lineCount', CountSheet."Line Count");
        PayloadObject.Add('varianceLineCount', CountSheet."Variance Line Count");
        PayloadObject.Add('posted', CountSheet.Posted);
        PayloadObject.Add('closedDateTime', MessageMgt.IsoDateTime(CountSheet."Closed At"));
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;
}
