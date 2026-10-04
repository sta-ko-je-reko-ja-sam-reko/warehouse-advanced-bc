codeunit 59002 "WHA Integration Tests"
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
    procedure RequestedWorkIsHeldWhenTheSetupSaysSo()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A warehouse that wants to check requested work before it reaches the floor gets a
        // draft task, not a released one. The message still succeeds — holding is not failing.
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();
        HoldRequestedWork();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-HOLD', '', TaskRequestPayload('WHAPick', 5));
        IntegrationMessage.Get(EntryNo);

        Assert.IsTrue(MessageMgt.Process(IntegrationMessage), 'Holding requested work should still apply the message.');

        WarehouseTask.SetRange(Quantity, 5);
        Assert.IsTrue(WarehouseTask.FindFirst(), 'The request should still have created a warehouse task.');
        Assert.AreEqual(WarehouseTask.Status::WHACreated, WarehouseTask.Status, 'Requested work should be held as a draft when the setup says so.');
    end;

    [Test]
    procedure AMessageCanOverrideTheHoldDecision()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A partner system that distinguishes urgent work from work to be checked can say so
        // per message, and that beats the standing setting.
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();
        HoldRequestedWork();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-OVERRIDE', '', ReleaseOverridePayload(true));
        IntegrationMessage.Get(EntryNo);

        Assert.IsTrue(MessageMgt.Process(IntegrationMessage), 'The request should be applied.');

        WarehouseTask.SetRange(Quantity, 6);
        Assert.IsTrue(WarehouseTask.FindFirst(), 'The request should have created a warehouse task.');
        Assert.AreEqual(WarehouseTask.Status::WHAReleased, WarehouseTask.Status, 'A message asking for release should beat the standing setting.');
    end;

    [Test]
    procedure AMessageCanAskForWorkToBeHeld()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] And the other way round: a warehouse that normally releases everything still honours
        // a message that asks for this one to be checked first.
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-HOLDONE', '', ReleaseOverridePayload(false));
        IntegrationMessage.Get(EntryNo);

        Assert.IsTrue(MessageMgt.Process(IntegrationMessage), 'The request should be applied.');

        WarehouseTask.SetRange(Quantity, 6);
        Assert.IsTrue(WarehouseTask.FindFirst(), 'The request should have created a warehouse task.');
        Assert.AreEqual(WarehouseTask.Status::WHACreated, WarehouseTask.Status, 'A message asking to be held should not reach the floor.');
    end;

    [Test]
    procedure RequestWithoutALocationIsRefused()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] Completeness is checked by the handler, not by the release that used to follow it.
        // Work with nowhere to happen is refused even when requested work is held rather than released.
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureItem();
        HoldRequestedWork();

        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-NOWHERE', '', '{"taskType":"WHAPick","itemNumber":"WHA-INT-ITEM","quantity":9}');
        IntegrationMessage.Get(EntryNo);

        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'A request with no location should be refused.');

        IntegrationMessage.Get(EntryNo);
        Assert.ExpectedMessage('which location', IntegrationMessage."Error Message");

        WarehouseTask.SetRange(Quantity, 9);
        Assert.IsTrue(WarehouseTask.IsEmpty(), 'A refused request should leave no task behind.');
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

    [Test]
    procedure TheMessageLogIsOfferedToTheRetentionFramework()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        IntRetention: Codeunit "WHA Int. Retention";
    begin
        // [SCENARIO] The message log is the one table in this app that grows without a business event to
        // bound it. Rather than write a bespoke clean-up, it is offered to the framework Business Central
        // already has, so an administrator sets a policy in the place they set every other one.
        IntRetention.RegisterAllowedTable();

        Assert.IsTrue(RetenPolAllowedTables.IsAllowedTable(Database::"WHA Integration Message"), 'A retention policy should be possible for the message log.');
    end;

    [Test]
    procedure TheRetentionClockRunsFromWhenAMessageWasProcessed()
    var
        IntegrationMessage: Record "WHA Integration Message";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        IntRetention: Codeunit "WHA Int. Retention";
    begin
        // [SCENARIO] Age is measured from when the app finished with a message, not from when it arrived.
        // A message that sat unprocessed for a month has not been kept for a month; nobody has read it yet.
        IntRetention.RegisterAllowedTable();

        Assert.AreEqual(
            IntegrationMessage.FieldNo("Processed At"),
            RetenPolAllowedTables.GetDefaultDateFieldNo(Database::"WHA Integration Message"),
            'The retention clock should run from when the message was processed.');
    end;

    [Test]
    procedure AMessageCannotBeConfiguredAwayFasterThanAWeek()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        IntRetention: Codeunit "WHA Int. Retention";
    begin
        // [SCENARIO] The log is what an interface argument is settled from. A policy that could delete it
        // within a day would take the evidence away before anybody noticed there was a dispute.
        IntRetention.RegisterAllowedTable();

        Assert.AreEqual(
            IntRetention.MinimumRetentionDays(),
            RetenPolAllowedTables.GetMandatoryMinimumRetentionDays(Database::"WHA Integration Message"),
            'The framework should refuse a policy shorter than the minimum this feature insists on.');
    end;

    [Test]
    procedure ReleaseWithoutADocumentIsRefused()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A release names its document in the external ID and nowhere else. A message that
        // names nothing is refused, rather than releasing whichever document happens to sort first.
        EnsureIntegrationSetup(false);
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAWarehouseReceiptRelease, '', '', '{}');

        IntegrationMessage.Get(EntryNo);

        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'A release that names no receipt should not be applied.');
        Assert.AreEqual(IntegrationMessage.Status::WHAFailed, IntegrationMessage.Status, 'A release that names no receipt should fail.');
    end;

    [Test]
    procedure AdjustmentOfNothingIsRefused()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] A correction of zero changes no stock. Recording it would put a line in a journal
        // that adjusts nothing, so the message fails instead.
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnsureItem();
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAInventoryAdjustment, 'ADJ-ZERO-1', '', AdjustmentPayload(0));

        IntegrationMessage.Get(EntryNo);

        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'An adjustment of zero should not be applied.');
        Assert.AreEqual(IntegrationMessage.Status::WHAFailed, IntegrationMessage.Status, 'An adjustment of zero should fail.');
    end;

    [Test]
    procedure ReceiptIsReportedOnlyWhenNothingIsOpen()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        ReceiptCompleted: Codeunit "WHA Int. Receipt Completed";
        MessageType: Enum "WHA Int. Message Type";
        SourceType: Enum "WHA Task Source";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] A receipt is reported finished once, and only when no work against it is still open.
        // Reporting it while a put-away is outstanding would tell the partner system something untrue.
        EnsureIntegrationSetup(false);
        DocumentNo := 'WR-DONE-1';

        CreateSourceTask(WarehouseTask, 'TSK-WR-1', SourceType::WHAWhseReceipt, DocumentNo, 10000, true);
        CreateSourceTask(WarehouseTask, 'TSK-WR-2', SourceType::WHAWhseReceipt, DocumentNo, 20000, false);

        ReceiptCompleted.CollectOutbound();
        Assert.AreEqual(0, OutboundCount(MessageType::WHAWarehouseReceiptDone, DocumentNo), 'A receipt with work still open should not be reported.');

        WarehouseTask.Get('TSK-WR-2');
        WarehouseTask.Status := WarehouseTask.Status::WHACompleted;
        WarehouseTask."Completed At" := CurrentDateTime;
        WarehouseTask.Modify(false);

        ReceiptCompleted.CollectOutbound();
        Assert.AreEqual(1, OutboundCount(MessageType::WHAWarehouseReceiptDone, DocumentNo), 'A receipt whose work is finished should be reported once.');

        ReceiptCompleted.CollectOutbound();
        Assert.AreEqual(1, OutboundCount(MessageType::WHAWarehouseReceiptDone, DocumentNo), 'A second sweep should not report the same receipt again.');
    end;

    [Test]
    procedure ClosedCountIsReportedOncePerSheet()
    var
        CountSheet: Record "WHA Count Sheet";
        CountResult: Codeunit "WHA Int. Count Result";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [SCENARIO] A count is reported when it closes, and the outbox is what remembers that it was —
        // no flag is kept on the sheet, so a second sweep has to find the message rather than a marker.
        EnsureIntegrationSetup(false);
        EnsureLocation();

        CountSheet.Init();
        CountSheet."No." := 'CNT-INT-1';
        CountSheet."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(CountSheet."Location Code"));
        CountSheet.Status := CountSheet.Status::WHAClosed;
        CountSheet."Closed At" := CurrentDateTime;
        CountSheet.Insert(true);

        CountResult.CollectOutbound();
        CountResult.CollectOutbound();

        Assert.AreEqual(1, OutboundCount(MessageType::WHACountResult, CountSheet."No."), 'A closed sheet should be reported exactly once.');
    end;

    [Test]
    procedure StockPositionIsOneStatementPerLocation()
    var
        HandlingUnit: Record "WHA Handling Unit";
        IntegrationMessage: Record "WHA Integration Message";
        StockPosition: Codeunit "WHA Int. Stock Position";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [SCENARIO] Two pallets standing in the same place produce one statement, not two. The statement
        // is per location and per day, which is what makes it comparable with what the partner believes.
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnsureItem();

        CreateStockedUnit(HandlingUnit, 'HU-POS-1', 3);
        CreateStockedUnit(HandlingUnit, 'HU-POS-2', 2);

        StockPosition.CollectOutbound();
        StockPosition.CollectOutbound();

        IntegrationMessage.SetRange("Message Type", MessageType::WHAStockPosition);
        IntegrationMessage.SetRange(Direction, IntegrationMessage.Direction::WHAOutbound);
        IntegrationMessage.SetFilter("External Id", StrSubstNo('%1|*', LocationTok));

        Assert.AreEqual(1, IntegrationMessage.Count(), 'One location on one day should produce one statement.');
    end;

    [Test]
    procedure TheScheduledRunStopsWhenTheFeatureIsOff()
    var
        Setup: Record "WHA Integration Setup";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
    begin
        // [SCENARIO] A job queue entry left behind after somebody switches the feature off stops rather
        // than carrying on. Every other scheduled run in this app guards the same way; this one did not.
        EnsureIntegrationSetup(false);
        Setup.Get();
        Setup.Validate("WHA Enabled", false);
        Setup.Modify(true);

        asserterror MessageMgt.Run();

        Setup.Validate("WHA Enabled", true);
        Setup.Modify(true);
    end;

    [Test]
    procedure AnAdjustmentIsHandedToThePostingMethod()
    var
        IntegrationMessage: Record "WHA Integration Message";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        Recorder: Codeunit "WHA Test Posting Recorder";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [GIVEN] The integration surface posts through the recording method
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnsureItem();
        UsePostingMethod(Enum::"WHA Posting Method"::WHATestRecorder);
        Recorder.Forget();

        // [WHEN] The partner system reports three fewer than Business Central believes
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAInventoryAdjustment, 'ADJ-REC-NEG', '', AdjustmentPayload(-3));
        IntegrationMessage.Get(EntryNo);

        // [THEN] The message is applied and one negative adjustment of three is asked for, traceable to it
        Assert.IsTrue(MessageMgt.Process(IntegrationMessage), 'The adjustment should be applied.');
        Assert.AreEqual(1, Recorder.Recorded(TempPostingRequest), 'One line should reach the posting method.');
        TempPostingRequest.FindFirst();
        Assert.AreEqual(TempPostingRequest."Posting Type"::WHANegativeAdjustment, TempPostingRequest."Posting Type", 'Fewer than expected is a negative adjustment.');
        Assert.AreEqual(3, TempPostingRequest.Quantity, 'The quantity is posted as a positive number.');
        Assert.AreEqual('ADJ-REC-NEG', TempPostingRequest."Document No.", 'The external ID is the document number.');
        Assert.AreEqual(Database::"WHA Integration Message", TempPostingRequest."Source Table No.", 'The line points back at the message table.');
        Assert.AreEqual(EntryNo, TempPostingRequest."Source Line No.", 'The line points back at the message.');
        Assert.AreEqual('Adjustment from TESTHOST', TempPostingRequest.Description, 'The line says who sent it.');

        UsePostingMethod(Enum::"WHA Posting Method"::WHANone);
    end;

    [Test]
    procedure MoreThanExpectedIsAPositiveAdjustment()
    var
        IntegrationMessage: Record "WHA Integration Message";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        Recorder: Codeunit "WHA Test Posting Recorder";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [GIVEN] The integration surface posts through the recording method
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnsureItem();
        UsePostingMethod(Enum::"WHA Posting Method"::WHATestRecorder);
        Recorder.Forget();

        // [WHEN] The partner system reports four more than Business Central believes
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAInventoryAdjustment, 'ADJ-REC-POS', '', AdjustmentPayload(4));
        IntegrationMessage.Get(EntryNo);
        MessageMgt.Process(IntegrationMessage);

        // [THEN] A positive adjustment of four is asked for at the location
        Recorder.Recorded(TempPostingRequest);
        TempPostingRequest.FindFirst();
        Assert.AreEqual(TempPostingRequest."Posting Type"::WHAPositiveAdjustment, TempPostingRequest."Posting Type", 'More than expected is a positive adjustment.');
        Assert.AreEqual(4, TempPostingRequest.Quantity, 'Four go in.');
        Assert.AreEqual(LocationTok, TempPostingRequest."Location Code", 'The adjustment happens where the message said.');

        UsePostingMethod(Enum::"WHA Posting Method"::WHANone);
    end;

    [Test]
    procedure AnAdjustmentNothingPostsFails()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        EntryNo: Integer;
    begin
        // [SCENARIO] Under the default method nothing is posted. The message fails rather than being marked
        // done, so the partner system's correction is not silently lost.
        // [GIVEN] The integration surface set not to post
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnsureItem();
        UsePostingMethod(Enum::"WHA Posting Method"::WHANone);

        // [WHEN] An adjustment arrives and is processed
        EntryNo := MessageMgt.CreateInbound(MessageType::WHAInventoryAdjustment, 'ADJ-NONE-1', '', AdjustmentPayload(5));
        IntegrationMessage.Get(EntryNo);

        // [THEN] It fails, saying nothing took the line
        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'An adjustment nothing posted should not count as applied.');
        IntegrationMessage.Get(EntryNo);
        Assert.ExpectedMessage('took no line', IntegrationMessage."Error Message");
    end;

    [Test]
    procedure TheSameAdjustmentIsNotMadeTwice()
    var
        FirstMessage: Record "WHA Integration Message";
        SecondMessage: Record "WHA Integration Message";
        Recorder: Codeunit "WHA Test Posting Recorder";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] An adjustment that has already been applied
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnsureItem();
        UsePostingMethod(Enum::"WHA Posting Method"::WHATestRecorder);
        Recorder.Forget();
        FirstMessage.Get(MessageMgt.CreateInbound(MessageType::WHAInventoryAdjustment, 'ADJ-REC-DUP', '', AdjustmentPayload(2)));
        MessageMgt.Process(FirstMessage);

        // [WHEN] The partner system sends it again
        SecondMessage.Get(MessageMgt.CreateInbound(MessageType::WHAInventoryAdjustment, 'ADJ-REC-DUP', '', AdjustmentPayload(2)));

        // [THEN] The second is refused, because adjusting twice would double the correction
        Assert.IsFalse(MessageMgt.Process(SecondMessage), 'The same adjustment should not be applied twice.');
        SecondMessage.Get(SecondMessage."Entry No.");
        Assert.ExpectedMessage('already been made', SecondMessage."Error Message");

        UsePostingMethod(Enum::"WHA Posting Method"::WHANone);
    end;

    [Test]
    procedure AnAdjustmentMustNameItsItemAndLocation()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] The integration surface set up
        EnsureIntegrationSetup(false);

        // [WHEN] An adjustment names no item
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHAInventoryAdjustment, 'ADJ-NOITEM', '', '{"locationCode":"WHAINT","quantity":1}'));
        // [THEN] It fails, saying the item is missing
        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'An adjustment of no item should fail.');
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        Assert.ExpectedMessage('does not say which item', IntegrationMessage."Error Message");

        // [WHEN] An adjustment names no location
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHAInventoryAdjustment, 'ADJ-NOLOC', '', '{"itemNumber":"WHA-INT-ITEM","quantity":1}'));
        // [THEN] It fails, saying where is missing
        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'An adjustment at no location should fail.');
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        Assert.ExpectedMessage('does not say where the adjustment happens', IntegrationMessage."Error Message");
    end;

    [Test]
    procedure ACancelledMessageIsNotApplied()
    var
        IntegrationMessage: Record "WHA Integration Message";
        WarehouseTask: Record "WHA Warehouse Task";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [SCENARIO] Cancelling is how somebody says a message was deliberately dropped. Applying it later,
        // by hand or through the API, would do the very thing that was decided against.
        // [GIVEN] A task request that somebody cancelled
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-CANCELLED', '', TaskRequestPayload('WHAPick', 7)));
        MessageMgt.Cancel(IntegrationMessage);

        // [WHEN] Somebody tries to apply it
        asserterror MessageMgt.Process(IntegrationMessage);

        // [THEN] It is refused and no task was created
        Assert.ExpectedError('is already Cancelled');
        WarehouseTask.SetRange(Quantity, 7);
        WarehouseTask.SetRange("Location Code", LocationTok);
        Assert.IsTrue(WarehouseTask.IsEmpty(), 'A cancelled request should create no work.');
    end;

    [Test]
    procedure AnAppliedMessageCannotBeAppliedAgain()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] A task request that has been applied
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureLocation();
        EnsureItem();
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-TWICE', '', TaskRequestPayload('WHAPick', 1)));
        MessageMgt.Process(IntegrationMessage);

        // [WHEN] It is processed again, or cancelled afterwards
        // [THEN] Both are refused
        asserterror MessageMgt.Process(IntegrationMessage);
        Assert.ExpectedError('is already Processed');
        asserterror MessageMgt.Cancel(IntegrationMessage);
        Assert.ExpectedError('is already Processed');
    end;

    [Test]
    procedure AFailedMessageIsTriedAgainUpToTheLimit()
    var
        IntegrationMessage: Record "WHA Integration Message";
        Setup: Record "WHA Integration Setup";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] A setup that allows two attempts, and a request that cannot succeed
        EnsureIntegrationSetup(false);
        Setup.Get();
        Setup.Validate("Max Retry Count", 2);
        Setup.Modify(true);
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-RETRY', '', '{"taskType":"WHAPick","itemNumber":"WHA-INT-ITEM","quantity":1}'));
        MessageMgt.Process(IntegrationMessage);
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        Assert.AreEqual(1, IntegrationMessage."Retry Count", 'The first failure is counted.');

        // [WHEN] The queue runs twice more
        MessageMgt.ProcessQueue();
        MessageMgt.ProcessQueue();

        // [THEN] It was tried once more and then left alone, still failed
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        Assert.AreEqual(2, IntegrationMessage."Retry Count", 'A message is not tried more often than the setup allows.');
        Assert.AreEqual(IntegrationMessage.Status::WHAFailed, IntegrationMessage.Status, 'A message that keeps failing stays failed.');

        EnsureIntegrationSetup(false);
    end;

    [Test]
    procedure AFailedMessageSucceedsOnceTheCauseIsPutRight()
    var
        IntegrationMessage: Record "WHA Integration Message";
        Location: Record Location;
        Setup: Record "WHA Integration Setup";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] Retrying allowed, and a request for a location that does not exist yet
        EnsureIntegrationSetup(false);
        EnsureTaskNumbering();
        EnsureItem();
        Setup.Get();
        Setup.Validate("Max Retry Count", 3);
        Setup.Modify(true);
        if Location.Get('WHAINTLATE') then
            Location.Delete(false);
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'REQ-LATE', '', '{"taskType":"WHAPick","locationCode":"WHAINTLATE","itemNumber":"WHA-INT-ITEM","quantity":1}'));
        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'A request for a location nobody has created fails.');

        // [WHEN] The location is created and the queue runs
        Location.Init();
        Location.Code := 'WHAINTLATE';
        Location.Insert(false);
        MessageMgt.ProcessQueue();

        // [THEN] The message is applied and its error is cleared
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        Assert.AreEqual(IntegrationMessage.Status::WHAProcessed, IntegrationMessage.Status, 'The retry should apply the message.');
        Assert.AreEqual('', IntegrationMessage."Error Message", 'An applied message carries no error.');
        Assert.AreNotEqual(0DT, IntegrationMessage."Processed At", 'An applied message says when.');

        EnsureIntegrationSetup(false);
    end;

    [Test]
    procedure ACountRequestRaisesASheetWhereItWasAskedFor()
    var
        CountSheet: Record "WHA Count Sheet";
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        SheetRef: RecordRef;
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] Counting switched on with numbering
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnableCounting(true);

        // [WHEN] The partner system asks for a count at the location
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHACountRequest, CopyStr(LocationTok, 1, 50), '', '{}'));

        // [THEN] The message is applied and points at a sheet for that location, due today, saying who asked
        Assert.IsTrue(MessageMgt.Process(IntegrationMessage), 'A count request should be applied.');
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        SheetRef.Get(IntegrationMessage."Record ID");
        SheetRef.SetTable(CountSheet);
        Assert.AreEqual(LocationTok, CountSheet."Location Code", 'The sheet counts the location in the external ID.');
        Assert.AreEqual(WorkDate(), CountSheet."Due Date", 'The count is due today.');
        Assert.AreEqual('Requested by TESTHOST', CountSheet.Description, 'The sheet says who asked for it.');
    end;

    [Test]
    procedure ACountIsNotRaisedWhileCountingIsOff()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] Counting switched off
        EnsureIntegrationSetup(false);
        EnableCounting(false);

        // [WHEN] The partner system asks for a count
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHACountRequest, 'WHAINTOFF', '', '{}'));

        // [THEN] It fails, saying counting is off
        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'A count cannot be raised while counting is off.');
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        Assert.ExpectedMessage('Counting is switched off', IntegrationMessage."Error Message");
    end;

    [Test]
    procedure ACountRequestMustSayWhereToCount()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] Counting switched on
        EnsureIntegrationSetup(false);
        EnableCounting(true);

        // [WHEN] A count request arrives with no external ID
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHACountRequest, '', '', '{}'));

        // [THEN] It fails, saying where the location belongs
        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'A count of nowhere should fail.');
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        Assert.ExpectedMessage('does not say where to count', IntegrationMessage."Error Message");
    end;

    [Test]
    procedure AShippedUnitIsReportedOnceWithWhatItHeld()
    var
        HandlingUnit: Record "WHA Handling Unit";
        IntegrationMessage: Record "WHA Integration Message";
        HUShipped: Codeunit "WHA Int. HU Shipped";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        PayloadObject: JsonObject;
        LineArray: JsonArray;
    begin
        // [GIVEN] A unit holding four of an item that has been shipped
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnsureItem();
        CreateStockedUnit(HandlingUnit, 'HU-SHIP-RPT', 4);
        HandlingUnit.Status := HandlingUnit.Status::WHAShipped;
        HandlingUnit.Modify(false);

        // [WHEN] The outbox is swept twice
        HUShipped.CollectOutbound();
        HUShipped.CollectOutbound();

        // [THEN] One despatch notification names the unit and carries its one line
        Assert.AreEqual(1, OutboundCount(MessageType::WHAHandlingUnitShipped, 'HU-SHIP-RPT'), 'A shipped unit is reported exactly once.');
        FindOutbound(IntegrationMessage, MessageType::WHAHandlingUnitShipped, 'HU-SHIP-RPT');
        Assert.IsTrue(MessageMgt.TryReadPayload(IntegrationMessage, PayloadObject), 'The notification carries a JSON body.');
        Assert.AreEqual('HU-SHIP-RPT', MessageMgt.JsonText(PayloadObject, 'number'), 'The notification names the unit.');
        Assert.AreEqual('WHAShipped', MessageMgt.JsonText(PayloadObject, 'status'), 'The notification says the unit has shipped.');
        Assert.IsTrue(MessageMgt.JsonArray(PayloadObject, 'lines', LineArray), 'The notification lists the contents.');
        Assert.AreEqual(1, LineArray.Count(), 'The unit held one line.');
    end;

    [Test]
    procedure AnOpenUnitIsNotReportedAsShipped()
    var
        HandlingUnit: Record "WHA Handling Unit";
        HUShipped: Codeunit "WHA Int. HU Shipped";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] A unit that is still open
        EnsureIntegrationSetup(false);
        EnsureLocation();
        EnsureItem();
        CreateStockedUnit(HandlingUnit, 'HU-SHIP-OPEN', 1);

        // [WHEN] The outbox is swept
        HUShipped.CollectOutbound();

        // [THEN] Nothing is reported for it
        Assert.AreEqual(0, OutboundCount(MessageType::WHAHandlingUnitShipped, 'HU-SHIP-OPEN'), 'A unit still on site is not reported as shipped.');
    end;

    [Test]
    procedure ADespatchNotificationCannotArriveFromThePartner()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        // [GIVEN] An inbound message of a type that is only ever sent
        EnsureIntegrationSetup(false);
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHAHandlingUnitShipped, 'HU-IN-1', '', '{}'));

        // [WHEN] It is processed
        // [THEN] It fails with a readable reason
        Assert.IsFalse(MessageMgt.Process(IntegrationMessage), 'A despatch notification cannot be applied here.');
        IntegrationMessage.Get(IntegrationMessage."Entry No.");
        Assert.ExpectedMessage('only ever sent to the partner system', IntegrationMessage."Error Message");
    end;

    [Test]
    procedure AShipmentIsReportedWithWhatCameUpShort()
    var
        IntegrationMessage: Record "WHA Integration Message";
        WarehouseTask: Record "WHA Warehouse Task";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        ShipmentCompleted: Codeunit "WHA Int. Shipment Completed";
        MessageType: Enum "WHA Int. Message Type";
        SourceType: Enum "WHA Task Source";
        PayloadObject: JsonObject;
    begin
        // [GIVEN] A shipment with two finished picks, one of which found three of the five it asked for
        EnsureIntegrationSetup(false);
        CreateSourceTask(WarehouseTask, 'TSK-WS-S1', SourceType::WHAWhseShipment, 'WS-SHORT-1', 10000, true);
        CreateSourceTask(WarehouseTask, 'TSK-WS-S2', SourceType::WHAWhseShipment, 'WS-SHORT-1', 20000, true);
        WarehouseTask.Get('TSK-WS-S2');
        WarehouseTask.Quantity := 5;
        WarehouseTask."Quantity Handled" := 3;
        WarehouseTask.Modify(false);

        // [WHEN] The outbox is swept twice
        ShipmentCompleted.CollectOutbound();
        ShipmentCompleted.CollectOutbound();

        // [THEN] The shipment is reported once, with both jobs, four handled and two short
        Assert.AreEqual(1, OutboundCount(MessageType::WHAWarehouseShipmentDone, 'WS-SHORT-1'), 'A finished shipment is reported exactly once.');
        FindOutbound(IntegrationMessage, MessageType::WHAWarehouseShipmentDone, 'WS-SHORT-1');
        MessageMgt.TryReadPayload(IntegrationMessage, PayloadObject);
        Assert.AreEqual('WS-SHORT-1', MessageMgt.JsonText(PayloadObject, 'warehouseShipmentNumber'), 'The report names the shipment.');
        Assert.AreEqual(2, MessageMgt.JsonInteger(PayloadObject, 'tasksCompleted'), 'Both jobs are counted.');
        Assert.AreEqual(4, MessageMgt.JsonDecimal(PayloadObject, 'quantityHandled'), 'One and three were handled.');
        Assert.AreEqual(2, MessageMgt.JsonDecimal(PayloadObject, 'quantityShort'), 'Two were not found.');
    end;

    [Test]
    procedure ACancelledJobDoesNotHoldBackTheReceiptReport()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        ReceiptCompleted: Codeunit "WHA Int. Receipt Completed";
        MessageType: Enum "WHA Int. Message Type";
        SourceType: Enum "WHA Task Source";
    begin
        // [GIVEN] A receipt with one finished job and one that was cancelled
        EnsureIntegrationSetup(false);
        CreateSourceTask(WarehouseTask, 'TSK-WR-C1', SourceType::WHAWhseReceipt, 'WR-CANC-1', 10000, true);
        CreateSourceTask(WarehouseTask, 'TSK-WR-C2', SourceType::WHAWhseReceipt, 'WR-CANC-1', 20000, false);
        WarehouseTask.Get('TSK-WR-C2');
        WarehouseTask.Status := WarehouseTask.Status::WHACancelled;
        WarehouseTask.Modify(false);

        // [WHEN] The outbox is swept
        ReceiptCompleted.CollectOutbound();

        // [THEN] The receipt is reported, because nothing on it is still open
        Assert.AreEqual(1, OutboundCount(MessageType::WHAWarehouseReceiptDone, 'WR-CANC-1'), 'A cancelled job is not open work.');
    end;

    [Test]
    procedure TheJsonReadersFallBackRatherThanFail()
    var
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        PayloadObject: JsonObject;
        LineArray: JsonArray;
    begin
        // [SCENARIO] Payload shapes are assumed rather than specified, so every reader answers a safe
        // default for a key that is missing, empty or of the wrong kind.
        // [GIVEN] A payload with a text, a number, a null, a flag, a date, an object and an array
        PayloadObject.ReadFrom('{"text":"abc","number":"12.5","nothing":null,"flag":true,"date":"2026-03-14","object":{"a":1},"lines":[1,2]}');

        // [THEN] Each reader answers what is there, and a default where nothing usable is
        Assert.AreEqual('abc', MessageMgt.JsonText(PayloadObject, 'text'), 'A text value is read.');
        Assert.AreEqual('', MessageMgt.JsonText(PayloadObject, 'missing'), 'A missing key reads as empty.');
        Assert.AreEqual('', MessageMgt.JsonText(PayloadObject, 'nothing'), 'A null reads as empty.');
        Assert.AreEqual('', MessageMgt.JsonText(PayloadObject, 'object'), 'An object is not a text value.');
        Assert.IsFalse(MessageMgt.JsonHasValue(PayloadObject, 'nothing'), 'A null is not a value.');
        Assert.IsTrue(MessageMgt.JsonHasValue(PayloadObject, 'text'), 'A text is a value.');
        Assert.AreEqual(12.5, MessageMgt.JsonDecimal(PayloadObject, 'number'), 'A number written as text is read.');
        Assert.AreEqual(0, MessageMgt.JsonDecimal(PayloadObject, 'text'), 'Something that is not a number reads as zero.');
        Assert.AreEqual(0, MessageMgt.JsonInteger(PayloadObject, 'missing'), 'A missing integer reads as zero.');
        Assert.IsTrue(MessageMgt.JsonBoolean(PayloadObject, 'flag', false), 'A flag is read.');
        Assert.IsTrue(MessageMgt.JsonBoolean(PayloadObject, 'nothing', true), 'A null flag takes the default.');
        Assert.AreEqual(DMY2Date(14, 3, 2026), MessageMgt.JsonDate(PayloadObject, 'date'), 'An ISO date is read.');
        Assert.AreEqual(0D, MessageMgt.JsonDate(PayloadObject, 'text'), 'Something that is not a date reads as no date.');
        Assert.IsTrue(MessageMgt.JsonArray(PayloadObject, 'lines', LineArray), 'An array is read.');
        Assert.AreEqual(2, LineArray.Count(), 'The array keeps its elements.');
        Assert.IsFalse(MessageMgt.JsonArray(PayloadObject, 'text', LineArray), 'A text is not an array.');
        Assert.AreEqual('', MessageMgt.IsoDateTime(0DT), 'No time at all is written as empty.');
    end;

    [Test]
    procedure APayloadThatIsNotJsonIsNotRead()
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        PayloadObject: JsonObject;
    begin
        // [GIVEN] A message whose body is not JSON
        IntegrationMessage.Init();
        MessageMgt.SetPayload(IntegrationMessage, 'this is not json');

        // [THEN] It cannot be read as a JSON object
        Assert.IsFalse(MessageMgt.TryReadPayload(IntegrationMessage, PayloadObject), 'Text that is not JSON is not read.');

        // [WHEN] The body is cleared
        MessageMgt.SetPayload(IntegrationMessage, '');
        // [THEN] There is nothing to read
        Assert.AreEqual('', MessageMgt.GetPayload(IntegrationMessage), 'A cleared body is empty.');
        Assert.IsFalse(MessageMgt.TryReadPayload(IntegrationMessage, PayloadObject), 'An empty body is not read.');
    end;

    [Test]
    procedure AnOutboundMessageIsOnlyWrittenOnce()
    var
        HandlingUnit: Record "WHA Handling Unit";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
        FirstEntryNo: Integer;
    begin
        // [GIVEN] An outbound message already written for an external ID
        FirstEntryNo := MessageMgt.CreateOutbound(MessageType::WHAStockPosition, 'WHA-OUT-ONCE', '{}', HandlingUnit.RecordId());

        // [WHEN] The same message is written again
        // [THEN] Nothing new is written, and the outbox says it already has one
        Assert.AreNotEqual(0, FirstEntryNo, 'The first message is written.');
        Assert.AreEqual(0, MessageMgt.CreateOutbound(MessageType::WHAStockPosition, 'WHA-OUT-ONCE', '{}', HandlingUnit.RecordId()), 'The second is not.');
        Assert.IsTrue(MessageMgt.HasOutbound(MessageType::WHAStockPosition, 'WHA-OUT-ONCE'), 'The outbox has the message.');
    end;

    [Test]
    procedure TheScheduledRunNamesTheFeatureThatIsOff()
    var
        Setup: Record "WHA Integration Setup";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
    begin
        // [GIVEN] The integration feature switched off
        EnsureIntegrationSetup(false);
        Setup.Get();
        Setup.Validate("WHA Enabled", false);
        Setup.Modify(true);

        // [WHEN] The scheduled run starts
        asserterror MessageMgt.Run();

        // [THEN] It stops, saying the feature is off
        Assert.ExpectedError('The Integration feature is not enabled');
    end;

    local procedure UsePostingMethod(Method: Enum "WHA Posting Method")
    var
        Setup: Record "WHA Integration Setup";
    begin
        Setup.Get();
        Setup."Posting Method" := Method;
        Setup.Modify(false);
    end;

    local procedure EnableCounting(Enabled: Boolean)
    var
        CountSetup: Record "WHA Count Setup";
    begin
        EnsureNoSeries('WHA-TEST-ICNT', 'ICS00001', 'ICS99999');
        if not CountSetup.Get() then begin
            CountSetup.Init();
            CountSetup.Insert(true);
        end;
        CountSetup."WHA Enabled" := Enabled;
        CountSetup."Count Sheet Nos." := 'WHA-TEST-ICNT';
        CountSetup.Modify(false);
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

    local procedure ReleaseOverridePayload(Release: Boolean): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('taskType', 'WHAMovement');
        PayloadObject.Add('description', 'Release decided by the message');
        PayloadObject.Add('locationCode', LocationTok);
        PayloadObject.Add('itemNumber', ItemTok);
        PayloadObject.Add('quantity', 6);
        PayloadObject.Add('release', Release);
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
        Setup.Validate("Release Requested Work", true);
        Setup.Validate("Max Retry Count", 0);
        Setup.Modify(true);

        EnsureTasksAreNotAutoReleased();
    end;

    local procedure HoldRequestedWork()
    var
        Setup: Record "WHA Integration Setup";
    begin
        Setup.Get();
        Setup.Validate("Release Requested Work", false);
        Setup.Modify(true);
    end;

    local procedure EnsureTasksAreNotAutoReleased()
    var
        TaskSetup: Record "WHA Warehouse Task Setup";
    begin
        TaskSetup.Reset();
        if not TaskSetup.Get() then begin
            TaskSetup.Init();
            TaskSetup.Insert(true);
        end;

        TaskSetup.Validate("Auto Release Tasks", false);
        TaskSetup.Modify(true);
    end;

    local procedure EnsureTaskNumbering()
    var
        TaskSetup: Record "WHA Warehouse Task Setup";
    begin
        EnsureNoSeries(CopyStr(TaskSeriesTok, 1, 20), 'TSK00001', 'TSK99999');

        TaskSetup.Reset();
        if not TaskSetup.Get() then begin
            TaskSetup.Init();
            TaskSetup.Insert(true);
        end;
        TaskSetup.Validate("Warehouse Task Nos.", TaskSeriesTok);
        TaskSetup.Modify(true);
    end;

    local procedure EnsureUnitNumbering()
    var
        HandlingUnitSetup: Record "WHA Handling Unit Setup";
    begin
        EnsureNoSeries(CopyStr(UnitSeriesTok, 1, 20), 'THU00001', 'THU99999');

        HandlingUnitSetup.Reset();
        if not HandlingUnitSetup.Get() then begin
            HandlingUnitSetup.Init();
            HandlingUnitSetup.Insert(true);
        end;
        HandlingUnitSetup.Validate("Handling Unit Nos.", UnitSeriesTok);
        HandlingUnitSetup.Modify(true);
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

    local procedure CreateSourceTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20]; SourceType: Enum "WHA Task Source"; SourceNo: Code[20]; SourceLineNo: Integer; Completed: Boolean)
    begin
        EnsureLocation();

        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(WarehouseTask."Location Code"));
        WarehouseTask."Item No." := CopyStr(ItemTok, 1, MaxStrLen(WarehouseTask."Item No."));
        WarehouseTask.Quantity := 1;
        WarehouseTask."Source Type" := SourceType;
        WarehouseTask."Source No." := SourceNo;
        WarehouseTask."Source Line No." := SourceLineNo;
        if Completed then begin
            WarehouseTask.Status := WarehouseTask.Status::WHACompleted;
            WarehouseTask."Quantity Handled" := 1;
            WarehouseTask."Completed At" := CurrentDateTime;
        end else
            WarehouseTask.Status := WarehouseTask.Status::WHAReleased;
        WarehouseTask.Insert(true);
    end;

    local procedure CreateStockedUnit(var HandlingUnit: Record "WHA Handling Unit"; UnitNo: Code[20]; Qty: Decimal)
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(HandlingUnit."Location Code"));
        HandlingUnit.Insert(true);

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := HandlingUnit."No.";
        HandlingUnitLine."Line No." := 10000;
        HandlingUnitLine."Item No." := CopyStr(ItemTok, 1, MaxStrLen(HandlingUnitLine."Item No."));
        HandlingUnitLine.Quantity := Qty;
        HandlingUnitLine.Insert(true);
    end;

    local procedure AdjustmentPayload(Qty: Decimal): Text
    var
        PayloadObject: JsonObject;
        PayloadText: Text;
    begin
        PayloadObject.Add('itemNumber', ItemTok);
        PayloadObject.Add('locationCode', LocationTok);
        PayloadObject.Add('quantity', Qty);
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

}
