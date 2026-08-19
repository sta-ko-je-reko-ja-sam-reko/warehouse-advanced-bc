namespace WarehouseAdvanced.Integration;

using Microsoft.Utilities;

codeunit 50653 "WHA Int. Message Mgt."
{
    Access = Public;

    var
        NotInboundErr: Label 'Integration message %1 is outbound. An outbound message is collected by the partner system and then acknowledged, not applied here.', Comment = '%1 = the message entry number';
        NotOutboundErr: Label 'Integration message %1 is inbound. An inbound message is applied here, not acknowledged.', Comment = '%1 = the message entry number';
        AlreadyDoneErr: Label 'Integration message %1 is already %2.', Comment = '%1 = the message entry number, %2 = the current status';
        NoRecordErr: Label 'Integration message %1 does not point at a record.', Comment = '%1 = the message entry number';

    /// <summary>
    /// The job queue entry point. Applies the inbound messages that are waiting, then fills the outbox
    /// with anything the partner system has not been told about yet.
    /// </summary>
    trigger OnRun()
    begin
        ProcessQueue();
        SweepOutbound();
    end;

    /// <summary>
    /// Records a message received from the partner system, and applies it straight away when the setup
    /// asks for that.
    /// </summary>
    /// <param name="MessageType">What the message is about.</param>
    /// <param name="ExternalId">How the partner system identifies what the message is about.</param>
    /// <param name="CorrelationId">The identifier that ties an answer back to its request. May be blank.</param>
    /// <param name="PayloadText">The message body, as JSON.</param>
    /// <returns>The entry number of the message that was recorded.</returns>
    procedure CreateInbound(MessageType: Enum "WHA Int. Message Type"; ExternalId: Code[50]; CorrelationId: Code[50]; PayloadText: Text): Integer
    var
        IntegrationMessage: Record "WHA Integration Message";
        Setup: Record "WHA Integration Setup";
    begin
        IntegrationMessage.Init();
        IntegrationMessage.Direction := IntegrationMessage.Direction::WHAInbound;
        IntegrationMessage."Message Type" := MessageType;
        IntegrationMessage."External Id" := ExternalId;
        IntegrationMessage."Correlation Id" := CorrelationId;
        IntegrationMessage.Status := IntegrationMessage.Status::WHANew;
        SetPayload(IntegrationMessage, PayloadText);
        IntegrationMessage.Insert(true);

        Setup.SetLoadFields("Auto Process Inbound");
        if Setup.Get() then
            if Setup."Auto Process Inbound" then
                Process(IntegrationMessage);

        exit(IntegrationMessage."Entry No.");
    end;

    /// <summary>
    /// Puts a message in the outbox for the partner system to collect. Does nothing when a message of
    /// this type already exists for the same external identifier, so a sweep can run as often as it
    /// likes.
    /// </summary>
    /// <param name="MessageType">What the message is about.</param>
    /// <param name="ExternalId">How this side identifies what the message is about, normally the record number.</param>
    /// <param name="PayloadText">The message body, as JSON.</param>
    /// <param name="SourceRecordId">The record the message was built from.</param>
    /// <returns>The entry number of the message, or zero when one already existed.</returns>
    procedure CreateOutbound(MessageType: Enum "WHA Int. Message Type"; ExternalId: Code[50]; PayloadText: Text; SourceRecordId: RecordId): Integer
    var
        IntegrationMessage: Record "WHA Integration Message";
    begin
        if HasOutbound(MessageType, ExternalId) then
            exit(0);

        IntegrationMessage.Init();
        IntegrationMessage.Direction := IntegrationMessage.Direction::WHAOutbound;
        IntegrationMessage."Message Type" := MessageType;
        IntegrationMessage."External Id" := ExternalId;
        IntegrationMessage.Status := IntegrationMessage.Status::WHANew;
        IntegrationMessage."Record ID" := SourceRecordId;
        SetPayload(IntegrationMessage, PayloadText);
        IntegrationMessage.Insert(true);

        exit(IntegrationMessage."Entry No.");
    end;

    /// <summary>
    /// Determines whether the outbox already holds a message of this type for this identifier.
    /// </summary>
    /// <param name="MessageType">The message type to look for.</param>
    /// <param name="ExternalId">The identifier to look for.</param>
    /// <returns>True when the partner system has already been told.</returns>
    procedure HasOutbound(MessageType: Enum "WHA Int. Message Type"; ExternalId: Code[50]): Boolean
    var
        IntegrationMessage: Record "WHA Integration Message";
    begin
        IntegrationMessage.SetLoadFields("Entry No.");
        IntegrationMessage.SetCurrentKey("Message Type", "External Id");
        IntegrationMessage.SetRange("Message Type", MessageType);
        IntegrationMessage.SetRange("External Id", ExternalId);
        IntegrationMessage.SetRange(Direction, IntegrationMessage.Direction::WHAOutbound);
        exit(not IntegrationMessage.IsEmpty());
    end;

    /// <summary>
    /// Determines whether an inbound message of this type and identifier has already been applied. This
    /// is what stops the partner system sending the same instruction twice.
    /// </summary>
    /// <param name="MessageType">The message type to look for.</param>
    /// <param name="ExternalId">The identifier to look for.</param>
    /// <param name="ExcludeEntryNo">The message being applied right now, which is not a duplicate of itself.</param>
    /// <returns>True when the same instruction has already been carried out.</returns>
    procedure HasProcessedInbound(MessageType: Enum "WHA Int. Message Type"; ExternalId: Code[50]; ExcludeEntryNo: Integer): Boolean
    var
        IntegrationMessage: Record "WHA Integration Message";
    begin
        if ExternalId = '' then
            exit(false);

        IntegrationMessage.SetLoadFields("Entry No.");
        IntegrationMessage.SetCurrentKey("Message Type", "External Id");
        IntegrationMessage.SetRange("Message Type", MessageType);
        IntegrationMessage.SetRange("External Id", ExternalId);
        IntegrationMessage.SetRange(Direction, IntegrationMessage.Direction::WHAInbound);
        IntegrationMessage.SetRange(Status, IntegrationMessage.Status::WHAProcessed);
        IntegrationMessage.SetFilter("Entry No.", '<>%1', ExcludeEntryNo);
        exit(not IntegrationMessage.IsEmpty());
    end;

    /// <summary>
    /// Applies one inbound message. A message that fails keeps its error text and is counted, so it can
    /// be looked at or tried again; nothing it did is left behind.
    /// </summary>
    /// <param name="IntegrationMessage">The message to apply.</param>
    /// <returns>True when the message was applied.</returns>
    procedure Process(var IntegrationMessage: Record "WHA Integration Message"): Boolean
    var
        MessageRunner: Codeunit "WHA Int. Message Runner";
    begin
        if IntegrationMessage.Direction <> IntegrationMessage.Direction::WHAInbound then
            Error(NotInboundErr, IntegrationMessage."Entry No.");
        if IntegrationMessage.Status = IntegrationMessage.Status::WHAProcessed then
            Error(AlreadyDoneErr, IntegrationMessage."Entry No.", IntegrationMessage.Status);

        ClearLastError();
        if not MessageRunner.Run(IntegrationMessage) then begin
            RecordFailure(IntegrationMessage, CopyStr(GetLastErrorText(), 1, MaxStrLen(IntegrationMessage."Error Message")));
            exit(false);
        end;

        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        IntegrationMessage.Status := IntegrationMessage.Status::WHAProcessed;
        IntegrationMessage."Error Message" := '';
        IntegrationMessage."Processed At" := CurrentDateTime;
        IntegrationMessage.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Records that the partner system has collected an outbound message.
    /// </summary>
    /// <param name="IntegrationMessage">The message that was collected.</param>
    procedure Acknowledge(var IntegrationMessage: Record "WHA Integration Message")
    begin
        if IntegrationMessage.Direction <> IntegrationMessage.Direction::WHAOutbound then
            Error(NotOutboundErr, IntegrationMessage."Entry No.");
        if IntegrationMessage.Status = IntegrationMessage.Status::WHAProcessed then
            Error(AlreadyDoneErr, IntegrationMessage."Entry No.", IntegrationMessage.Status);

        IntegrationMessage.Status := IntegrationMessage.Status::WHAProcessed;
        IntegrationMessage."Processed At" := CurrentDateTime;
        IntegrationMessage.Modify(true);
    end;

    /// <summary>
    /// Drops a message that should not be acted on, keeping it as a record that it arrived.
    /// </summary>
    /// <param name="IntegrationMessage">The message to cancel.</param>
    procedure Cancel(var IntegrationMessage: Record "WHA Integration Message")
    begin
        if IntegrationMessage.Status in [IntegrationMessage.Status::WHAProcessed, IntegrationMessage.Status::WHACancelled] then
            Error(AlreadyDoneErr, IntegrationMessage."Entry No.", IntegrationMessage.Status);

        IntegrationMessage.Status := IntegrationMessage.Status::WHACancelled;
        IntegrationMessage.Modify(true);
    end;

    /// <summary>
    /// Applies every inbound message that is waiting, and tries failed ones again while they are within
    /// the retry count the setup allows.
    /// </summary>
    procedure ProcessQueue()
    var
        IntegrationMessage: Record "WHA Integration Message";
    begin
        IntegrationMessage.SetCurrentKey(Direction, Status, "Message Type");
        IntegrationMessage.SetRange(Direction, IntegrationMessage.Direction::WHAInbound);
        IntegrationMessage.SetRange(Status, IntegrationMessage.Status::WHANew);
        if IntegrationMessage.FindSet() then
            repeat
                Process(IntegrationMessage);
            until IntegrationMessage.Next() = 0;

        RetryFailed();
    end;

    /// <summary>
    /// Asks every message type to add whatever the partner system has not been told about yet.
    /// </summary>
    procedure SweepOutbound()
    var
        Handler: Interface "WHA IIntMessageHandler";
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"WHA Int. Message Type".Ordinals() do begin
            Handler := Enum::"WHA Int. Message Type".FromInteger(Ordinal);
            Handler.CollectOutbound();
        end;
    end;

    /// <summary>
    /// Writes the message body. Does not save the record — the caller inserts or modifies it.
    /// </summary>
    /// <param name="IntegrationMessage">The message to write to.</param>
    /// <param name="PayloadText">The message body, as JSON.</param>
    procedure SetPayload(var IntegrationMessage: Record "WHA Integration Message"; PayloadText: Text)
    var
        PayloadOutStream: OutStream;
    begin
        Clear(IntegrationMessage.Payload);
        if PayloadText = '' then
            exit;

        IntegrationMessage.Payload.CreateOutStream(PayloadOutStream, TextEncoding::UTF8);
        PayloadOutStream.WriteText(PayloadText);
    end;

    /// <summary>
    /// Reads the message body.
    /// </summary>
    /// <param name="IntegrationMessage">The message to read.</param>
    /// <returns>The message body, as JSON, or an empty text when there is none.</returns>
    procedure GetPayload(var IntegrationMessage: Record "WHA Integration Message"): Text
    var
        PayloadInStream: InStream;
        PayloadBuilder: TextBuilder;
        LineText: Text;
    begin
        IntegrationMessage.CalcFields(Payload);
        if not IntegrationMessage.Payload.HasValue() then
            exit('');

        IntegrationMessage.Payload.CreateInStream(PayloadInStream, TextEncoding::UTF8);
        while not PayloadInStream.EOS() do begin
            PayloadInStream.ReadText(LineText);
            PayloadBuilder.Append(LineText);
        end;
        exit(PayloadBuilder.ToText());
    end;

    /// <summary>
    /// Reads the message body as a JSON object.
    /// </summary>
    /// <param name="IntegrationMessage">The message to read.</param>
    /// <param name="PayloadObject">Receives the parsed body.</param>
    /// <returns>True when the body is a JSON object.</returns>
    procedure TryReadPayload(var IntegrationMessage: Record "WHA Integration Message"; var PayloadObject: JsonObject): Boolean
    var
        PayloadText: Text;
    begin
        PayloadText := GetPayload(IntegrationMessage);
        if PayloadText = '' then
            exit(false);
        exit(PayloadObject.ReadFrom(PayloadText));
    end;

    /// <summary>
    /// Reads a text value from a JSON object.
    /// </summary>
    /// <param name="PayloadObject">The object to read from.</param>
    /// <param name="KeyName">The name of the value.</param>
    /// <returns>The value, or an empty text when it is absent or null.</returns>
    procedure JsonText(PayloadObject: JsonObject; KeyName: Text): Text
    var
        ValueToken: JsonToken;
    begin
        if not PayloadObject.Get(KeyName, ValueToken) then
            exit('');
        if not ValueToken.IsValue() then
            exit('');
        if ValueToken.AsValue().IsNull() then
            exit('');
        exit(ValueToken.AsValue().AsText());
    end;

    /// <summary>
    /// Reads a decimal value from a JSON object.
    /// </summary>
    /// <param name="PayloadObject">The object to read from.</param>
    /// <param name="KeyName">The name of the value.</param>
    /// <returns>The value, or zero when it is absent or not a number.</returns>
    procedure JsonDecimal(PayloadObject: JsonObject; KeyName: Text): Decimal
    var
        NumberValue: Decimal;
        RawValue: Text;
    begin
        RawValue := JsonText(PayloadObject, KeyName);
        if RawValue = '' then
            exit(0);
        if not Evaluate(NumberValue, RawValue, 9) then
            exit(0);
        exit(NumberValue);
    end;

    /// <summary>
    /// Reads an integer value from a JSON object.
    /// </summary>
    /// <param name="PayloadObject">The object to read from.</param>
    /// <param name="KeyName">The name of the value.</param>
    /// <returns>The value, or zero when it is absent or not a number.</returns>
    procedure JsonInteger(PayloadObject: JsonObject; KeyName: Text): Integer
    var
        NumberValue: Integer;
        RawValue: Text;
    begin
        RawValue := JsonText(PayloadObject, KeyName);
        if RawValue = '' then
            exit(0);
        if not Evaluate(NumberValue, RawValue, 9) then
            exit(0);
        exit(NumberValue);
    end;

    /// <summary>
    /// Reads a date value from a JSON object, in the ISO form the partner system sends.
    /// </summary>
    /// <param name="PayloadObject">The object to read from.</param>
    /// <param name="KeyName">The name of the value.</param>
    /// <returns>The value, or a blank date when it is absent or unreadable.</returns>
    procedure JsonDate(PayloadObject: JsonObject; KeyName: Text): Date
    var
        DateValue: Date;
        RawValue: Text;
    begin
        RawValue := JsonText(PayloadObject, KeyName);
        if RawValue = '' then
            exit(0D);
        if not Evaluate(DateValue, RawValue, 9) then
            exit(0D);
        exit(DateValue);
    end;

    /// <summary>
    /// Reads an array from a JSON object.
    /// </summary>
    /// <param name="PayloadObject">The object to read from.</param>
    /// <param name="KeyName">The name of the array.</param>
    /// <param name="ValueArray">Receives the array.</param>
    /// <returns>True when the object holds an array under that name.</returns>
    procedure JsonArray(PayloadObject: JsonObject; KeyName: Text; var ValueArray: JsonArray): Boolean
    var
        ValueToken: JsonToken;
    begin
        if not PayloadObject.Get(KeyName, ValueToken) then
            exit(false);
        if not ValueToken.IsArray() then
            exit(false);

        ValueArray := ValueToken.AsArray();
        exit(true);
    end;

    /// <summary>
    /// Formats a date and time the way a message carries it, so every payload this app writes agrees on
    /// one shape.
    /// </summary>
    /// <param name="Value">The date and time to format.</param>
    /// <returns>The ISO 8601 form, or an empty text when there is no value.</returns>
    procedure IsoDateTime(Value: DateTime): Text
    begin
        if Value = 0DT then
            exit('');
        exit(Format(Value, 0, 9));
    end;

    /// <summary>
    /// Opens the record a message created, changed, or was built from.
    /// </summary>
    /// <param name="IntegrationMessage">The message to follow.</param>
    procedure ShowRecord(var IntegrationMessage: Record "WHA Integration Message")
    var
        PageManagement: Codeunit "Page Management";
        SourceRecordRef: RecordRef;
    begin
        if not SourceRecordRef.Get(IntegrationMessage."Record ID") then
            Error(NoRecordErr, IntegrationMessage."Entry No.");

        PageManagement.PageRun(SourceRecordRef);
    end;

    local procedure RetryFailed()
    var
        IntegrationMessage: Record "WHA Integration Message";
        Setup: Record "WHA Integration Setup";
    begin
        Setup.SetLoadFields("Max Retry Count");
        if not Setup.Get() then
            exit;
        if Setup."Max Retry Count" <= 0 then
            exit;

        IntegrationMessage.SetCurrentKey(Direction, Status, "Message Type");
        IntegrationMessage.SetRange(Direction, IntegrationMessage.Direction::WHAInbound);
        IntegrationMessage.SetRange(Status, IntegrationMessage.Status::WHAFailed);
        IntegrationMessage.SetFilter("Retry Count", '<%1', Setup."Max Retry Count");
        if IntegrationMessage.FindSet() then
            repeat
                Process(IntegrationMessage);
            until IntegrationMessage.Next() = 0;
    end;

    local procedure RecordFailure(var IntegrationMessage: Record "WHA Integration Message"; ErrorText: Text[250])
    begin
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        IntegrationMessage.Status := IntegrationMessage.Status::WHAFailed;
        IntegrationMessage."Error Message" := ErrorText;
        IntegrationMessage."Retry Count" += 1;
        IntegrationMessage.Modify(true);
    end;
}
