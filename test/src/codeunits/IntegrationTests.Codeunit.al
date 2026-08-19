codeunit 51002 "WHA Integration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TaskSeriesTok: Label 'WHA-TEST-TASK', Locked = true;
        UnitSeriesTok: Label 'WHA-TEST-HU', Locked = true;
        LocationTok: Label 'WHAINT', Locked = true;
        ItemTok: Label 'WHA-INT-ITEM', Locked = true;

    [Test]
    procedure PayloadRoundTrips()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] What the partner system sent is what comes back out, byte for byte. Everything else
        // in the feature reads the payload through these two calls.
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'ROUNDTRIP-1', '', '{"taskType":"WHAPick","quantity":3}');

        IntegrationMessage.Get(EntryNo);

        Assert.AreEqual('{"taskType":"WHAPick","quantity":3}', MessageMgt.GetPayload(IntegrationMessage), 'The payload should come back exactly as it went in.');
    end;

    [Test]
    procedure ArrivalIsStamped()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A message records when it arrived and which system it belongs to, without the
        // caller having to say so.
        EnsureIntegrationSetup(false);
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'STAMP-1', '', '{}');

        IntegrationMessage.Get(EntryNo);

        Assert.IsTrue(IntegrationMessage."Received At" <> 0DT, 'A new message should record when it arrived.');
        Assert.AreEqual('TESTHOST', IntegrationMessage."Partner System", 'A new message should take the partner system from the setup.');
        Assert.AreEqual(IntegrationMessage.Status::WHANew, IntegrationMessage.Status, 'A new message should be waiting.');
    end;

    [Test]
    procedure UnknownTypeFailsWithAReadableReason()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A message type nothing is bound to is refused with an explanation, not dropped in
        // silence. This is the default implementation of the handler interface doing its job.
        EnsureIntegrationSetup(false);
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAUnknown, 'UNKNOWN-1', '', '{}');
        IntegrationMessage.Get(EntryNo);

        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'A message with no handler should not be applied.');

        IntegrationMessage.Get(EntryNo);
        Assert.AreEqual(IntegrationMessage.Status::WHAFailed, IntegrationMessage.Status, 'A message with no handler should fail.');
        Assert.AreEqual(1, IntegrationMessage."Retry Count", 'A failure should be counted.');
        Assert.IsTrue(IntegrationMessage."Error Message" <> '', 'A failure should say why.');
    end;

    [Test]
    procedure OutboundOnlyTypeCannotBeApplied()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A confirmation is something this app sends. One arriving inbound is a mistake on
        // the partner's side and is refused as such.
        EnsureIntegrationSetup(false);
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskConfirmed, 'WRONGWAY-1', '', '{}');
        IntegrationMessage.Get(EntryNo);

        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'A confirmation should not be applied inbound.');

        IntegrationMessage.Get(EntryNo);
        Assert.AreEqual(IntegrationMessage.Status::WHAFailed, IntegrationMessage.Status, 'An outbound-only type should fail inbound.');
    end;

    [Test]
    procedure TaskRequestCreatesAndReleasesATask()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A request for work becomes a released warehouse task, numbered by this app, and the
        // message points at what it created.
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-1', '', TaskRequestPayload('WHAPick', 4));
        IntegrationMessage.Get(EntryNo);

        Assert.IsTrue(MessageMgt.Process(IntegrationMessage), 'A complete request should be applied.');

        WarehouseTask.SetRange("Item No.", ItemTok);
        WarehouseTask.SetRange(Quantity, 4);
        Assert.IsTrue(WarehouseTask.FindFirst(), 'The request should have created a warehouse task.');
        Assert.AreEqual(WarehouseTask.Status::WHAReleased, WarehouseTask.Status, 'A task created from a request should be released for the floor.');
        Assert.AreEqual(WarehouseTask."Task Type"::WHAPick, WarehouseTask."Task Type", 'The task type should come from the request.');

        IntegrationMessage.Get(EntryNo);
        Assert.AreEqual(WarehouseTask.RecordId(), IntegrationMessage."Record ID", 'The message should point at the task it created.');
    end;

    [Test]
    procedure IncompleteRequestCreatesNothing()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A request that names neither a handling unit nor an item is refused, and no
        // half-built task is left behind.
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-EMPTY', '', '{"taskType":"WHAPick","locationCode":"WHAINT"}');
        IntegrationMessage.Get(EntryNo);

        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'An empty request should be refused.');

        IntegrationMessage.Get(EntryNo);
        Assert.ExpectedMessage('neither a handling unit nor an item', IntegrationMessage."Error Message");
    end;

    [Test]
    procedure UnknownTaskTypeIsRefused()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A task type this app does not have is named back to the partner, rather than
        // quietly turning into something else.
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-BADTYPE', '', TaskRequestPayload('WHACrossDock', 1));
        IntegrationMessage.Get(EntryNo);

        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'An unknown task type should be refused.');

        IntegrationMessage.Get(EntryNo);
        Assert.ExpectedMessage('WHACrossDock', IntegrationMessage."Error Message");
    end;

    [Test]
    procedure SameRequestIsNotAppliedTwice()
    var
        FirstMessage: Record "WHA Integration Message";
        SecondMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        FirstEntryNo: Integer;
        SecondEntryNo: Integer;
    begin
        // [SCENARIO] The partner system resending the same instruction does not create the work twice.
        // The external identifier is what makes that safe.
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();

        FirstEntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-DUP', '', TaskRequestPayload('WHAPick', 2));
        FirstMessage.Get(FirstEntryNo);
        Assert.IsTrue(MessageMgt.Process(FirstMessage), 'The first request should be applied.');

        SecondEntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-DUP', '', TaskRequestPayload('WHAPick', 2));
        SecondMessage.Get(SecondEntryNo);

        Assert.IsFalse(MessageMgt.Process(SecondMessage), 'The same request should not be applied twice.');

        SecondMessage.Get(SecondEntryNo);
        Assert.ExpectedMessage('already been created', SecondMessage."Error Message");
    end;

    [Test]
    procedure ReceiptCreatesAUnitWithItsContents()
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A receipt notification becomes a handling unit with a content line, numbered by
        // this app rather than by the partner.
        EnsureIntegrationSetup(false);
        EnsureUnitNumbering();
        EnsureLocation();
        EnsureItem();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAHandlingUnitReceived, 'HU-1', '', ReceiptPayload());
        IntegrationMessage.Get(EntryNo);

        Assert.IsTrue(MessageMgt.Process(IntegrationMessage), 'A receipt notification should be applied.');

        HandlingUnit.SetRange(SSCC, '380123456789012999');
        Assert.IsTrue(HandlingUnit.FindFirst(), 'The receipt should have created a handling unit.');
        Assert.AreNotEqual('', HandlingUnit."No.", 'The unit should be numbered from this app.');

        HandlingUnitLine.SetRange("Handling Unit No.", HandlingUnit."No.");
        Assert.AreEqual(1, HandlingUnitLine.Count(), 'The receipt should have created one content line.');
    end;

    [Test]
    procedure OutboundSweepReportsACompletedTaskOnce()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [SCENARIO] A completed task is put in the outbox once. The outbox itself is the record of what
        // has been sent, so sweeping again adds nothing.
        EnsureIntegrationSetup(false);
        CreateCompletedTask(WarehouseTask, 'INT-DONE-01');

        MessageMgt.SweepOutbound();
        Assert.IsTrue(MessageMgt.HasOutbound(MessageType::WHAWarehouseTaskConfirmed, 'INT-DONE-01'), 'A completed task should reach the outbox.');

        MessageMgt.SweepOutbound();

        Assert.AreEqual(1, OutboundCount(MessageType::WHAWarehouseTaskConfirmed, 'INT-DONE-01'), 'Sweeping twice should not report the same task twice.');
    end;

    [Test]
    procedure OutboundPayloadCarriesTheTask()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [SCENARIO] The confirmation the partner collects says which task was done and where it ended.
        EnsureIntegrationSetup(false);
        CreateCompletedTask(WarehouseTask, 'INT-DONE-02');

        MessageMgt.SweepOutbound();

        FindOutbound(IntegrationMessage, MessageType::WHAWarehouseTaskConfirmed, 'INT-DONE-02');
        Assert.ExpectedMessage('"number":"INT-DONE-02"', MessageMgt.GetPayload(IntegrationMessage));
        Assert.ExpectedMessage('"status":"WHACompleted"', MessageMgt.GetPayload(IntegrationMessage));
    end;

    [Test]
    procedure AcknowledgeClosesAnOutboundMessage()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [SCENARIO] The partner system says it has the message, and it stops being outstanding.
        EnsureIntegrationSetup(false);
        CreateCompletedTask(WarehouseTask, 'INT-DONE-03');
        MessageMgt.SweepOutbound();
        FindOutbound(IntegrationMessage, MessageType::WHAWarehouseTaskConfirmed, 'INT-DONE-03');

        MessageMgt.Acknowledge(IntegrationMessage);

        Assert.AreEqual(IntegrationMessage.Status::WHAProcessed, IntegrationMessage.Status, 'Acknowledging should close the message.');
        Assert.IsTrue(IntegrationMessage."Processed At" <> 0DT, 'Acknowledging should record when it happened.');
    end;

    [Test]
    procedure OutboundMessagesAreNotProcessedHere()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [SCENARIO] The two verbs are not interchangeable: an outbound message is collected and
        // acknowledged, never applied.
        EnsureIntegrationSetup(false);
        CreateCompletedTask(WarehouseTask, 'INT-DONE-04');
        MessageMgt.SweepOutbound();
        FindOutbound(IntegrationMessage, MessageType::WHAWarehouseTaskConfirmed, 'INT-DONE-04');

        asserterror MessageMgt.Process(IntegrationMessage);

        Assert.ExpectedError('is outbound');
    end;

    [Test]
    procedure InboundMessagesAreNotAcknowledged()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] The other half of the same rule.
        EnsureIntegrationSetup(false);
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'ACK-WRONG', '', '{}');
        IntegrationMessage.Get(EntryNo);

        asserterror MessageMgt.Acknowledge(IntegrationMessage);

        Assert.ExpectedError('is inbound');
    end;

    [Test]
    procedure CancellingKeepsTheMessage()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A message that should not be acted on is dropped deliberately, and the record that
        // it arrived survives.
        EnsureIntegrationSetup(false);
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'CANCEL-1', '', '{}');
        IntegrationMessage.Get(EntryNo);

        MessageMgt.Cancel(IntegrationMessage);

        IntegrationMessage.Get(EntryNo);
        Assert.AreEqual(IntegrationMessage.Status::WHACancelled, IntegrationMessage.Status, 'Cancelling should mark the message, not remove it.');
    end;

    [Test]
    procedure WaitingMessageCannotBeDeleted()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] Nothing disappears from the inbox unnoticed. A message that has not been dealt with
        // has to be cancelled first.
        EnsureIntegrationSetup(false);
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'DELETE-1', '', '{}');
        IntegrationMessage.Get(EntryNo);

        asserterror IntegrationMessage.Delete(true);

        Assert.ExpectedError('Cancel it first');
    end;

    [Test]
    procedure AutoProcessAppliesOnArrival()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] With the setup asking for it, a message is applied as it arrives rather than
        // waiting for someone to process the queue.
        EnsureIntegrationSetup(true);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'AUTO-1', '', TaskRequestPayload('WHAPutAway', 7));

        IntegrationMessage.Get(EntryNo);
        Assert.AreEqual(IntegrationMessage.Status::WHAProcessed, IntegrationMessage.Status, 'A message should be applied on arrival when the setup asks for it.');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        IntegrationMessage: Record "WHA Integration Message";
        DemoIntegration: Codeunit "WHA Demo Integration";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice creates the messages once. The importer is reachable
        // from both the guided setup wizard and the MCP tool, so a second run must be a no-op.
        DemoIntegration.Import();
        IntegrationMessage.SetFilter("External Id", 'DEMO-INT-*');
        CountAfterFirstRun := IntegrationMessage.Count();

        DemoIntegration.Import();

        Assert.AreEqual(5, CountAfterFirstRun, 'The first import should create five sample messages.');
        Assert.AreEqual(CountAfterFirstRun, IntegrationMessage.Count(), 'A second import should not create more messages.');
    end;

    local procedure OutboundCount(MessageType: Enum "WHA Int. Message Type"; ExternalId: Code[50]): Integer
    var
        IntegrationMessage: Record "WHA Integration Message";
    begin
        IntegrationMessage.SetRange("Message Type", MessageType);
        IntegrationMessage.SetRange("External Id", ExternalId);
        IntegrationMessage.SetRange(Direction, IntegrationMessage.Direction::WHAOutbound);
        exit(IntegrationMessage.Count());
    end;

    local procedure FindOutbound(var IntegrationMessage: Record "WHA Integration Message"; MessageType: Enum "WHA Int. Message Type"; ExternalId: Code[50])
    begin
        IntegrationMessage.Reset();
        IntegrationMessage.SetRange("Message Type", MessageType);
        IntegrationMessage.SetRange("External Id", ExternalId);
        IntegrationMessage.SetRange(Direction, IntegrationMessage.Direction::WHAOutbound);
        IntegrationMessage.FindFirst();
    end;

    local procedure CreateCompletedTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20])
    begin
        EnsureLocation();

        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(WarehouseTask."Location Code"));
        WarehouseTask."Item No." := CopyStr(ItemTok, 1, MaxStrLen(WarehouseTask."Item No."));
        WarehouseTask.Quantity := 1;
        WarehouseTask.Status := WarehouseTask.Status::WHACompleted;
        WarehouseTask."Completed At" := CurrentDateTime;
        WarehouseTask.Insert(true);
    end;

    local procedure TaskRequestPayload(TaskTypeName: Text; Qty: Decimal): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('taskType', TaskTypeName);
        PayloadObject.Add('description', 'Requested by the test');
        PayloadObject.Add('locationCode', LocationTok);
        PayloadObject.Add('itemNumber', ItemTok);
        PayloadObject.Add('quantity', Qty);
        PayloadObject.Add('priority', 10);
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure ReceiptPayload(): Text
    var
        PayloadObject: JsonObject;
        LineArray: JsonArray;
        LineObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('sscc', '380123456789012999');
        PayloadObject.Add('description', 'Received by the test');
        PayloadObject.Add('locationCode', LocationTok);

        LineObject.Add('itemNumber', ItemTok);
        LineObject.Add('quantity', 8);
        LineArray.Add(LineObject);
        PayloadObject.Add('lines', LineArray);

        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure EnsureIntegrationSetup(AutoProcess: Boolean)
    var
        Setup: Record "WHA Integration Setup";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;

        Setup."Partner System" := 'TESTHOST';
        Setup.Validate("Auto Process Inbound", AutoProcess);
        Setup.Validate("Max Retry Count", 0);
        Setup.Modify(true);
    end;

    local procedure EnsureTaskNumbering()
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        EnsureNoSeries(CopyStr(TaskSeriesTok, 1, 20), 'TSK00001', 'TSK99999');

        SetupLogic.EnsureExists(WarehouseSetup);
        WarehouseSetup.Validate("Warehouse Task Nos.", TaskSeriesTok);
        WarehouseSetup.Modify(true);
    end;

    local procedure EnsureUnitNumbering()
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        EnsureNoSeries(CopyStr(UnitSeriesTok, 1, 20), 'THU00001', 'THU99999');

        SetupLogic.EnsureExists(WarehouseSetup);
        WarehouseSetup.Validate("Handling Unit Nos.", UnitSeriesTok);
        WarehouseSetup.Modify(true);
    end;

    local procedure EnsureNoSeries(SeriesCode: Code[20]; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeries.Get(SeriesCode) then
            exit;

        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := SeriesCode;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := StartingNo;
        NoSeriesLine."Ending No." := EndingNo;
        NoSeriesLine.Insert();
    end;

    local procedure EnsureLocation()
    var
        Location: Record Location;
    begin
        if Location.Get(LocationTok) then
            exit;

        Location.Init();
        Location.Code := CopyStr(LocationTok, 1, MaxStrLen(Location.Code));
        Location.Insert();
    end;

    local procedure EnsureItem()
    var
        Item: Record Item;
    begin
        if Item.Get(ItemTok) then
            exit;

        Item.Init();
        Item."No." := CopyStr(ItemTok, 1, MaxStrLen(Item."No."));
        Item.Description := CopyStr(ItemTok, 1, MaxStrLen(Item.Description));
        Item.Insert();
    end;
}
