codeunit 51001 "WHA Warehouse Task Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLocationTok: Label 'WHATEST', Locked = true;
        TestBinTok: Label 'WHATEST-01', Locked = true;
        TestItemTok: Label 'WHA-TASK-IT', Locked = true;
        LastOrderNo: Code[20];

    [Test]
    procedure LocationChangeClearsBothBins()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Moving the work to another location clears both bins, so a bin belonging to the
        // previous location cannot be carried over.
        xWarehouseTask."Location Code" := 'BLUE';
        xWarehouseTask."From Bin Code" := 'B-01-0001';
        xWarehouseTask."To Bin Code" := 'B-02-0001';
        WarehouseTask := xWarehouseTask;
        WarehouseTask."Location Code" := 'RED';

        TaskLogic.Validate_LocationCode(WarehouseTask, xWarehouseTask);

        Assert.AreEqual('', WarehouseTask."From Bin Code", 'The from bin should be cleared when the location changes.');
        Assert.AreEqual('', WarehouseTask."To Bin Code", 'The to bin should be cleared when the location changes.');
    end;

    [Test]
    procedure SameLocationKeepsBins()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Revalidating the same location leaves the bins untouched.
        xWarehouseTask."Location Code" := 'BLUE';
        xWarehouseTask."From Bin Code" := 'B-01-0001';
        WarehouseTask := xWarehouseTask;

        TaskLogic.Validate_LocationCode(WarehouseTask, xWarehouseTask);

        Assert.AreEqual('B-01-0001', WarehouseTask."From Bin Code", 'The from bin should survive when the location is unchanged.');
    end;

    [Test]
    procedure NegativeQuantityIsRejected()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] A task cannot ask for a negative quantity to be moved.
        WarehouseTask.Quantity := -1;

        asserterror TaskLogic.Validate_Quantity(WarehouseTask, xWarehouseTask);

        Assert.ExpectedError('cannot be negative');
    end;

    [Test]
    procedure NegativePriorityIsRejected()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Priority counts upwards from zero, so a negative value is meaningless.
        WarehouseTask.Priority := -5;

        asserterror TaskLogic.Validate_Priority(WarehouseTask, xWarehouseTask);

        Assert.ExpectedError('cannot be negative');
    end;

    [Test]
    procedure ChangingItemClearsVariantAndUnitOfMeasure()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Changing the item clears the variant, so a variant of the previous item cannot be
        // carried over onto a different item.
        xWarehouseTask."Item No." := 'ITEM-A';
        xWarehouseTask."Variant Code" := 'RED';
        xWarehouseTask."Unit of Measure Code" := 'BOX';
        WarehouseTask := xWarehouseTask;
        WarehouseTask."Item No." := 'ITEM-B';

        TaskLogic.Validate_ItemNo(WarehouseTask, xWarehouseTask);

        Assert.AreEqual('', WarehouseTask."Variant Code", 'The variant should be cleared when the item changes.');
        Assert.AreEqual('', WarehouseTask."Unit of Measure Code", 'The unit of measure should be cleared when the item changes.');
    end;

    [Test]
    procedure ReleaseWithoutLocationIsRejected()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Work cannot reach the floor until it says where it happens.
        WarehouseTask."No." := 'TEST-NO-LOCATION';
        WarehouseTask."Item No." := 'ITEM-A';
        WarehouseTask.Quantity := 1;

        asserterror TaskLogic.Release(WarehouseTask);

        Assert.ExpectedError('Specify a location');
    end;

    [Test]
    procedure ReleaseWithNothingToMoveIsRejected()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Work cannot reach the floor until it says what is being moved.
        WarehouseTask."No." := 'TEST-NO-WORK';
        WarehouseTask."Location Code" := 'BLUE';

        asserterror TaskLogic.Release(WarehouseTask);

        Assert.ExpectedError('handling unit');
    end;

    [Test]
    procedure AssigningAnUnreleasedTaskIsRejected()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] A task that has not been released is not ready to be given to anyone.
        WarehouseTask."No." := 'TEST-UNRELEASED';
        WarehouseTask.Status := WarehouseTask.Status::WHACreated;
        WarehouseTask."Assigned To User ID" := 'OPERATOR';

        asserterror TaskLogic.Validate_AssignedToUserID(WarehouseTask, xWarehouseTask);

        Assert.ExpectedError('cannot be assigned');
    end;

    [Test]
    procedure AssigningMovesTaskToAssigned()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Naming a person on a released task hands it to them and stamps when it happened.
        WarehouseTask."No." := 'TEST-ASSIGN';
        WarehouseTask.Status := WarehouseTask.Status::WHAReleased;
        WarehouseTask."Assigned To User ID" := 'OPERATOR';

        TaskLogic.Validate_AssignedToUserID(WarehouseTask, xWarehouseTask);

        Assert.AreEqual(WarehouseTask.Status::WHAAssigned, WarehouseTask.Status, 'Naming a person should assign the task.');
        Assert.IsTrue(WarehouseTask."Assigned At" <> 0DT, 'Assigning should record when it happened.');
    end;

    [Test]
    procedure ClearingTheUserReturnsTaskToTheQueue()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Handing work back puts it in front of the next person who asks for it.
        xWarehouseTask."No." := 'TEST-HANDBACK';
        xWarehouseTask.Status := xWarehouseTask.Status::WHAAssigned;
        xWarehouseTask."Assigned To User ID" := 'OPERATOR';
        xWarehouseTask."Assigned At" := CurrentDateTime;
        WarehouseTask := xWarehouseTask;
        WarehouseTask."Assigned To User ID" := '';

        TaskLogic.Validate_AssignedToUserID(WarehouseTask, xWarehouseTask);

        Assert.AreEqual(WarehouseTask.Status::WHAReleased, WarehouseTask.Status, 'Handing a task back should release it again.');
        Assert.AreEqual(0DT, WarehouseTask."Assigned At", 'Handing a task back should clear when it was assigned.');
    end;

    [Test]
    procedure HandingBackStartedWorkReturnsItToTheQueue()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        xWarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] An operator who cannot finish a job they started hands it back, and it becomes work
        // anybody can pick up again. Leaving it in progress with nobody holding it would hide it from
        // the queue for ever.
        xWarehouseTask."No." := 'TEST-ABANDON';
        xWarehouseTask.Status := xWarehouseTask.Status::WHAInProgress;
        xWarehouseTask."Assigned To User ID" := 'OPERATOR';
        xWarehouseTask."Assigned At" := CurrentDateTime;
        xWarehouseTask."Started At" := CurrentDateTime;
        WarehouseTask := xWarehouseTask;
        WarehouseTask."Assigned To User ID" := '';

        TaskLogic.Validate_AssignedToUserID(WarehouseTask, xWarehouseTask);

        Assert.AreEqual(WarehouseTask.Status::WHAReleased, WarehouseTask.Status, 'Abandoned work should return to the queue.');
        Assert.AreEqual(0DT, WarehouseTask."Started At", 'Abandoned work should no longer claim to have been started.');
    end;

    [Test]
    procedure StartingAnUnassignedTaskIsRejected()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Nobody can start work that has not been given to them.
        WarehouseTask."No." := 'TEST-UNASSIGNED';
        WarehouseTask.Status := WarehouseTask.Status::WHAReleased;

        asserterror TaskLogic.Start(WarehouseTask);

        Assert.ExpectedError('must be assigned');
    end;

    [Test]
    procedure CompletingATaskThatIsNotStartedIsRejected()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Work is only complete once it has actually been started.
        WarehouseTask."No." := 'TEST-NOT-STARTED';
        WarehouseTask.Status := WarehouseTask.Status::WHAAssigned;

        asserterror TaskLogic.Complete(WarehouseTask);

        Assert.ExpectedError('in progress');
    end;

    [Test]
    procedure CompletedTaskCannotBeCancelled()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] Work that has already been done cannot be withdrawn.
        WarehouseTask."No." := 'TEST-DONE';
        WarehouseTask.Status := WarehouseTask.Status::WHACompleted;

        asserterror TaskLogic.Cancel(WarehouseTask);

        Assert.ExpectedError('cannot be cancelled');
    end;

    [Test]
    procedure CompletedTaskCannotBeDeleted()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] A completed task is the record that the work happened, so it is kept.
        WarehouseTask."No." := 'TEST-KEEP';
        WarehouseTask.Status := WarehouseTask.Status::WHACompleted;

        asserterror TaskLogic.Trigger_OnDelete(WarehouseTask);

        Assert.ExpectedError('cannot be deleted');
    end;

    [Test]
    procedure NewTaskTakesTheDefaultPriority()
    var
        Setup: Record "WHA Warehouse Task Setup";
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        // [SCENARIO] A task created without a priority is as urgent as the setup says by default.
        ConfigureQueue(0);
        EnsureTaskSetup(Setup);
        Setup.Validate("Default Priority", 70);
        Setup.Modify(true);

        WarehouseTask.Init();
        WarehouseTask."No." := 'TEST-PRIORITY';
        WarehouseTask.Insert(true);

        Assert.AreEqual(70, WarehouseTask.Priority, 'A new task should take the default priority from the setup.');
    end;

    [Test]
    procedure AutoReleaseNeedsSomethingToWorkOn()
    var
        Setup: Record "WHA Warehouse Task Setup";
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        // [SCENARIO] Releasing automatically must not push an empty task to the floor.
        EnsureTaskSetup(Setup);
        Setup.Validate("Auto Release Tasks", true);
        Setup.Modify(true);

        WarehouseTask.Init();
        WarehouseTask."No." := 'TEST-AUTO-EMPTY';
        WarehouseTask.Insert(true);

        Assert.AreEqual(WarehouseTask.Status::WHACreated, WarehouseTask.Status, 'A task with nothing to move should not be released automatically.');
    end;

    [Test]
    procedure AutoReleasePutsAReadyTaskOnTheFloor()
    var
        Setup: Record "WHA Warehouse Task Setup";
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        // [SCENARIO] A task that already says where the work is and what is moved skips the review step
        // when the setup asks for automatic release.
        EnsureTaskSetup(Setup);
        Setup.Validate("Auto Release Tasks", true);
        Setup.Modify(true);

        WarehouseTask.Init();
        WarehouseTask."No." := 'TEST-AUTO-READY';
        WarehouseTask."Location Code" := TestLocationTok;
        WarehouseTask."Item No." := 'TEST-ITEM';
        WarehouseTask.Quantity := 1;
        WarehouseTask.Insert(true);

        Assert.AreEqual(WarehouseTask.Status::WHAReleased, WarehouseTask.Status, 'A ready task should be released as it is created.');
    end;

    [Test]
    procedure LifeCycleRunsFromReleaseToCompletion()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        OperatorId: Code[50];
    begin
        // [SCENARIO] A task walks from created to completed through release, assignment and start,
        // recording the time at each step.
        ConfigureQueue(0);
        OperatorId := EnsureUser('WHA-LIFECYCLE');
        CreateWorkableTask(WarehouseTask, 'TEST-LIFECYCLE');

        TaskLogic.Release(WarehouseTask);
        Assert.AreEqual(WarehouseTask.Status::WHAReleased, WarehouseTask.Status, 'Releasing should make the task available.');

        TaskLogic.Assign(WarehouseTask, OperatorId);
        Assert.AreEqual(WarehouseTask.Status::WHAAssigned, WarehouseTask.Status, 'Assigning should hand the task over.');

        TaskLogic.Start(WarehouseTask);
        Assert.AreEqual(WarehouseTask.Status::WHAInProgress, WarehouseTask.Status, 'Starting should mark the task as being worked.');
        Assert.IsTrue(WarehouseTask."Started At" <> 0DT, 'Starting should record when the work began.');

        TaskLogic.Complete(WarehouseTask);
        Assert.AreEqual(WarehouseTask.Status::WHACompleted, WarehouseTask.Status, 'Completing should close the task.');
        Assert.IsTrue(WarehouseTask."Completed At" <> 0DT, 'Completing should record when the work finished.');
    end;

    [Test]
    procedure MostUrgentTaskIsOfferedFirst()
    var
        UrgentTask: Record "WHA Warehouse Task";
        RoutineTask: Record "WHA Warehouse Task";
        NextTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        OperatorId: Code[50];
    begin
        // [SCENARIO] Asking for work hands over the most urgent released task, and assigns it on the way.
        ConfigureQueue(0);
        OperatorId := EnsureUser('WHA-QUEUE');

        CreateWorkableTask(RoutineTask, 'TEST-QUEUE-ROUTINE');
        RoutineTask.Validate(Priority, 90);
        RoutineTask.Modify(true);
        TaskLogic.Release(RoutineTask);

        CreateWorkableTask(UrgentTask, 'TEST-QUEUE-URGENT');
        UrgentTask.Validate(Priority, 5);
        UrgentTask.Modify(true);
        TaskLogic.Release(UrgentTask);

        Assert.IsTrue(TaskLogic.GetNextForUser(OperatorId, TestLocationTok, NextTask), 'There should be work waiting.');

        Assert.AreEqual('TEST-QUEUE-URGENT', NextTask."No.", 'The most urgent task should be offered first.');
        Assert.AreEqual(NextTask.Status::WHAAssigned, NextTask.Status, 'Handing work over should assign it.');
        Assert.AreEqual(OperatorId, NextTask."Assigned To User ID", 'Handing work over should name the person who asked for it.');
    end;

    [Test]
    procedure OwnUnfinishedWorkComesBackFirst()
    var
        StartedTask: Record "WHA Warehouse Task";
        WaitingTask: Record "WHA Warehouse Task";
        NextTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        OperatorId: Code[50];
    begin
        // [SCENARIO] Work already in an operator's hands is offered again before anything new, however
        // urgent the new work is.
        ConfigureQueue(0);
        OperatorId := EnsureUser('WHA-OWNWORK');

        CreateWorkableTask(StartedTask, 'TEST-OWN-STARTED');
        TaskLogic.Release(StartedTask);
        TaskLogic.Assign(StartedTask, OperatorId);
        TaskLogic.Start(StartedTask);

        CreateWorkableTask(WaitingTask, 'TEST-OWN-WAITING');
        WaitingTask.Validate(Priority, 1);
        WaitingTask.Modify(true);
        TaskLogic.Release(WaitingTask);

        Assert.IsTrue(TaskLogic.GetNextForUser(OperatorId, TestLocationTok, NextTask), 'There should be work waiting.');

        Assert.AreEqual('TEST-OWN-STARTED', NextTask."No.", 'Work already started should be offered back before new work.');
    end;

    [Test]
    procedure CompletingMovesTheHandlingUnit()
    var
        HandlingUnit: Record "WHA Handling Unit";
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        OperatorId: Code[50];
    begin
        // [SCENARIO] Completing a task that carries a handling unit records the unit at the destination
        // the task named, so the two features agree on where the goods are.
        ConfigureQueue(0);
        EnsureLocationAndBin();
        OperatorId := EnsureUser('WHA-MOVER');

        HandlingUnit.Init();
        HandlingUnit."No." := 'TEST-TASK-HU';
        HandlingUnit."Location Code" := TestLocationTok;
        HandlingUnit.Insert(true);

        WarehouseTask.Init();
        WarehouseTask."No." := 'TEST-HU-MOVE';
        WarehouseTask."Location Code" := TestLocationTok;
        WarehouseTask."Handling Unit No." := HandlingUnit."No.";
        WarehouseTask."To Bin Code" := TestBinTok;
        WarehouseTask.Insert(true);

        TaskLogic.Release(WarehouseTask);
        TaskLogic.Assign(WarehouseTask, OperatorId);
        TaskLogic.Start(WarehouseTask);
        TaskLogic.Complete(WarehouseTask);

        HandlingUnit.Get('TEST-TASK-HU');
        Assert.AreEqual(TestBinTok, HandlingUnit."Bin Code", 'Completing the task should move the handling unit to the destination bin.');
    end;

    [Test]
    procedure ShippedHandlingUnitCannotBeGivenWork()
    var
        HandlingUnit: Record "WHA Handling Unit";
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        // [SCENARIO] A unit that has left the building cannot be the subject of new warehouse work.
        HandlingUnit.Init();
        HandlingUnit."No." := 'TEST-TASK-SHIPPED';
        HandlingUnit.Status := HandlingUnit.Status::WHAShipped;
        HandlingUnit.Insert(true);

        WarehouseTask.Init();
        WarehouseTask."No." := 'TEST-SHIPPED-WORK';

        asserterror WarehouseTask.Validate("Handling Unit No.", 'TEST-TASK-SHIPPED');

        Assert.ExpectedError('already been shipped');
    end;

    [Test]
    procedure UserTaskLimitIsEnforced()
    var
        FirstTask: Record "WHA Warehouse Task";
        SecondTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        OperatorId: Code[50];
    begin
        // [SCENARIO] One person can only hold as many tasks at a time as the setup allows.
        ConfigureQueue(1);
        OperatorId := EnsureUser('WHA-LIMITED');

        CreateWorkableTask(FirstTask, 'TEST-LIMIT-ONE');
        TaskLogic.Release(FirstTask);
        TaskLogic.Assign(FirstTask, OperatorId);

        CreateWorkableTask(SecondTask, 'TEST-LIMIT-TWO');
        TaskLogic.Release(SecondTask);

        asserterror TaskLogic.Assign(SecondTask, OperatorId);

        Assert.ExpectedError('already holds');
    end;

    [Test]
    procedure ShortPickRecordsWhatWasActuallyMoved()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        ShortReason: Enum "WHA Whse. Short Reason";
        OperatorId: Code[50];
    begin
        // [SCENARIO] The job asked for twelve and the shelf held four. The task closes with four and
        // says why the rest is missing. The quantity asked for is left alone, as the record of what was
        // wanted.
        ConfigureQueue(0);
        ConfigureFollowUp(false);
        OperatorId := EnsureUser('WHA-SHORT');
        CreateStartedTask(WarehouseTask, 'TEST-SHORT-1', 12, OperatorId);

        TaskLogic.CompleteShort(WarehouseTask, 4, ShortReason::WHANotEnough);

        Assert.AreEqual(WarehouseTask.Status::WHACompleted, WarehouseTask.Status, 'A short pick still finishes the job.');
        Assert.AreEqual(4, WarehouseTask."Quantity Handled", 'The task should record what was actually moved.');
        Assert.AreEqual(12, WarehouseTask.Quantity, 'The quantity asked for should be left as it was.');
        Assert.AreEqual(ShortReason::WHANotEnough, WarehouseTask."Short Reason", 'The task should record why the rest is missing.');
    end;

    [Test]
    procedure CompletingInFullRecordsTheWholeQuantity()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        OperatorId: Code[50];
    begin
        // [SCENARIO] A job done in full says so, so that what was moved reads the same way on every
        // finished task rather than being blank on most of them.
        ConfigureQueue(0);
        OperatorId := EnsureUser('WHA-FULL');
        CreateStartedTask(WarehouseTask, 'TEST-FULL-1', 7, OperatorId);

        TaskLogic.Complete(WarehouseTask);

        Assert.AreEqual(7, WarehouseTask."Quantity Handled", 'A job done in full should record the whole quantity as moved.');
    end;

    [Test]
    procedure ShortPickCannotClaimMoreThanWasAsked()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        ShortReason: Enum "WHA Whse. Short Reason";
        OperatorId: Code[50];
    begin
        // [SCENARIO] Reporting a job short is for finding less, never more. More than was asked for is a
        // different conversation and this is not it.
        ConfigureQueue(0);
        OperatorId := EnsureUser('WHA-OVER');
        CreateStartedTask(WarehouseTask, 'TEST-SHORT-OVER', 5, OperatorId);

        asserterror TaskLogic.CompleteShort(WarehouseTask, 9, ShortReason::WHANotEnough);

        Assert.ExpectedError('cannot have been moved');
    end;

    [Test]
    procedure AJobWithNoQuantityCannotBeShort()
    var
        HandlingUnit: Record "WHA Handling Unit";
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        ShortReason: Enum "WHA Whse. Short Reason";
        OperatorId: Code[50];
    begin
        // [SCENARIO] Moving a whole pallet is all or nothing. There is no partial version of it, so the
        // operator is told to hand it back instead.
        ConfigureQueue(0);
        OperatorId := EnsureUser('WHA-NOQTY');

        HandlingUnit.Init();
        HandlingUnit."No." := 'TEST-SHORT-HU';
        HandlingUnit."Location Code" := TestLocationTok;
        HandlingUnit.Insert(true);

        WarehouseTask.Init();
        WarehouseTask."No." := 'TEST-SHORT-NOQTY';
        WarehouseTask."Location Code" := TestLocationTok;
        WarehouseTask."Handling Unit No." := HandlingUnit."No.";
        WarehouseTask.Insert(true);
        TaskLogic.Release(WarehouseTask);
        TaskLogic.Assign(WarehouseTask, OperatorId);
        TaskLogic.Start(WarehouseTask);

        asserterror TaskLogic.CompleteShort(WarehouseTask, 0, ShortReason::WHANotFound);

        Assert.ExpectedError('does not move a counted quantity');
    end;

    [Test]
    procedure NoFollowUpIsRaisedUnlessTheSetupAsksForOne()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        FollowUpTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        ShortReason: Enum "WHA Whse. Short Reason";
        OperatorId: Code[50];
    begin
        // [SCENARIO] By default a shortfall is reported, not re-queued. Sending a second person to a bin
        // that was empty for the first one is how a warehouse gets busy without getting anything done.
        ConfigureQueue(0);
        ConfigureFollowUp(false);
        OperatorId := EnsureUser('WHA-NOFOLLOW');
        CreateStartedTask(WarehouseTask, 'TEST-NOFOLLOW', 10, OperatorId);

        TaskLogic.CompleteShort(WarehouseTask, 2, ShortReason::WHANotFound);

        FollowUpTask.SetRange(Quantity, 8);
        FollowUpTask.SetRange("Item No.", 'TEST-ITEM');
        Assert.IsTrue(FollowUpTask.IsEmpty(), 'No follow-up should be raised unless the setup asks for one.');
    end;

    [Test]
    procedure AFollowUpCarriesTheOutstandingQuantity()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        FollowUpTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        ShortReason: Enum "WHA Whse. Short Reason";
        OperatorId: Code[50];
    begin
        // [SCENARIO] With follow-ups switched on, whatever was not found becomes a new job for the
        // remainder, carrying where the work is and what it is for.
        ConfigureQueue(0);
        ConfigureFollowUp(true);
        OperatorId := EnsureUser('WHA-FOLLOW');
        CreateStartedTask(WarehouseTask, 'TEST-FOLLOW', 10, OperatorId);

        TaskLogic.CompleteShort(WarehouseTask, 3, ShortReason::WHANotEnough);

        FollowUpTask.SetRange(Quantity, 7);
        FollowUpTask.SetRange("Item No.", 'TEST-ITEM');
        Assert.IsTrue(FollowUpTask.FindFirst(), 'A follow-up should be raised for what was not found.');
        Assert.AreEqual(TestLocationTok, FollowUpTask."Location Code", 'The follow-up should be for the same location.');
        Assert.ExpectedMessage('TEST-FOLLOW', FollowUpTask.Description);
    end;

    [Test]
    procedure NothingFoundAtAllStillClosesTheJob()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        ShortReason: Enum "WHA Whse. Short Reason";
        OperatorId: Code[50];
    begin
        // [SCENARIO] An empty bin is an answer. The job closes with nothing moved and a reason, rather
        // than being handed back and offered to the next person to walk to the same empty bin.
        ConfigureQueue(0);
        ConfigureFollowUp(false);
        OperatorId := EnsureUser('WHA-EMPTY');
        CreateStartedTask(WarehouseTask, 'TEST-EMPTY-BIN', 6, OperatorId);

        TaskLogic.CompleteShort(WarehouseTask, 0, ShortReason::WHANotFound);

        Assert.AreEqual(WarehouseTask.Status::WHACompleted, WarehouseTask.Status, 'Finding nothing should still close the job.');
        Assert.AreEqual(0, WarehouseTask."Quantity Handled", 'Nothing moved should be recorded as nothing moved.');
        Assert.AreEqual(ShortReason::WHANotFound, WarehouseTask."Short Reason", 'The reason is what makes an empty bin useful information.');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        DemoWarehouseTask: Codeunit "WHA Demo Warehouse Task";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice creates the records once. The importer is reachable
        // from both the guided setup wizard and the MCP tool, so a second run must be a no-op.
        DemoWarehouseTask.Import();
        WarehouseTask.SetFilter("No.", 'DEMO-TASK-*');
        CountAfterFirstRun := WarehouseTask.Count();

        DemoWarehouseTask.Import();

        Assert.AreEqual(6, CountAfterFirstRun, 'The first import should create six sample warehouse tasks.');
        Assert.AreEqual(CountAfterFirstRun, WarehouseTask.Count(), 'A second import should not create more records.');
    end;

    [Test]
    procedure DemoImportCoversEveryTaskType()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        DemoWarehouseTask: Codeunit "WHA Demo Warehouse Task";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        // [SCENARIO] The sample data exercises every task type, so each is visible on the list.
        DemoWarehouseTask.Import();

        foreach TaskType in TaskType.Ordinals() do begin
            WarehouseTask.Reset();
            WarehouseTask.SetFilter("No.", 'DEMO-TASK-*');
            WarehouseTask.SetRange("Task Type", TaskType);
            Assert.IsFalse(WarehouseTask.IsEmpty(), 'The sample data should include a task of every type.');
        end;
    end;

    [Test]
    procedure RaisingWorkFromAReceiptPutsAPutAwayOnTheQueue()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        // [SCENARIO] Goods have arrived and are standing in the receiving bin. The queue should know about
        // them without anybody typing a task, and the job should say to take them out of that bin.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WR-01', 'PO-1001');
        AddReceiptLine('WHA-WR-01', 10000, 6);

        Assert.AreEqual(1, TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-01'), 'The one outstanding line should have raised one job.');

        FindTaskForSource(WarehouseTask, SourceType::WHAWhseReceipt, 'WHA-WR-01', 10000);
        Assert.AreEqual(TaskType::WHAPutAway, WarehouseTask."Task Type", 'Goods that have arrived are put away.');
        Assert.AreEqual(6, WarehouseTask.Quantity, 'The job should ask for what is still outstanding.');
        Assert.AreEqual(CopyStr(TestBinTok, 1, 20), WarehouseTask."From Bin Code", 'A put-away starts in the bin the receipt named.');
        Assert.AreEqual('', WarehouseTask."To Bin Code", 'Where it goes is not the receipt''s to say.');
    end;

    [Test]
    procedure RaisingWorkFromAShipmentPutsAPickOnTheQueue()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        // [SCENARIO] Goods are due to leave. The job should end at the shipping bin, and say nothing about
        // where the stock is to be found, because the document does not know.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateShipment('WHA-WS-01', 'SO-2001');
        AddShipmentLine('WHA-WS-01', 10000, 4);

        Assert.AreEqual(1, TaskSourceMgt.GenerateFrom(SourceType::WHAWhseShipment, 'WHA-WS-01'), 'The one outstanding line should have raised one job.');

        FindTaskForSource(WarehouseTask, SourceType::WHAWhseShipment, 'WHA-WS-01', 10000);
        Assert.AreEqual(TaskType::WHAPick, WarehouseTask."Task Type", 'Goods that are leaving are picked.');
        Assert.AreEqual(4, WarehouseTask.Quantity, 'The job should ask for what is still outstanding.');
        Assert.AreEqual(CopyStr(TestBinTok, 1, 20), WarehouseTask."To Bin Code", 'A pick ends in the bin the shipment named.');
        Assert.AreEqual('', WarehouseTask."From Bin Code", 'Where the stock is found is a question about stock, not about the document.');
    end;

    [Test]
    procedure ALineWithNothingOutstandingRaisesNoWork()
    var
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] A line that has already been dealt with is not work. Raising nothing is the right
        // answer and is not an error.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WR-02', 'PO-1002');
        AddReceiptLine('WHA-WR-02', 10000, 0);

        Assert.AreEqual(0, TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-02'), 'Nothing outstanding means nothing to raise.');
    end;

    [Test]
    procedure RaisingWorkTwiceAddsOnlyWhatIsMissing()
    var
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] Somebody presses the button again, or a line is added to a document that has already
        // been through it. Neither should double the warehouse's work.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WR-03', 'PO-1003');
        AddReceiptLine('WHA-WR-03', 10000, 5);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-03');

        Assert.AreEqual(0, TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-03'), 'Running it again should raise nothing.');

        AddReceiptLine('WHA-WR-03', 20000, 3);
        Assert.AreEqual(1, TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-03'), 'A line added afterwards should raise its own job and nothing else.');
    end;

    [Test]
    procedure WorkThatWasCancelledCanBeRaisedAgain()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] A job raised in error is cancelled, not deleted. The line it came from still wants
        // doing, so the document must be able to raise it again.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WR-04', 'PO-1004');
        AddReceiptLine('WHA-WR-04', 10000, 7);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-04');
        FindTaskForSource(WarehouseTask, SourceType::WHAWhseReceipt, 'WHA-WR-04', 10000);
        TaskLogic.Cancel(WarehouseTask);

        Assert.AreEqual(1, TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-04'), 'A cancelled job leaves the line uncovered, so it should be raised again.');
    end;

    [Test]
    procedure AJobRemembersTheOrderBehindTheDocument()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] The warehouse document is a step; the order is what somebody is waiting on. A job on
        // the floor has to be traceable to the second, not only to the first.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateShipment('WHA-WS-02', 'SO-2002');
        AddShipmentLine('WHA-WS-02', 10000, 2);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseShipment, 'WHA-WS-02');

        FindTaskForSource(WarehouseTask, SourceType::WHAWhseShipment, 'WHA-WS-02', 10000);
        Assert.AreEqual('SO-2002', WarehouseTask."Source Document No.", 'The job should name the order the shipment is serving.');
        Assert.AreNotEqual('', TaskSourceMgt.DescribeLink(WarehouseTask), 'The job should be able to say where it came from.');
    end;

    [Test]
    procedure AJobWhoseSourceLineIsFinishedIsNoLongerWanted()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] The goods were received by some other route. The job is still on the queue and is now
        // a walk nobody needs, which is worth being able to notice.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WR-05', 'PO-1005');
        AddReceiptLine('WHA-WR-05', 10000, 9);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-05');
        FindTaskForSource(WarehouseTask, SourceType::WHAWhseReceipt, 'WHA-WR-05', 10000);
        Assert.IsTrue(TaskSourceMgt.SourceIsOpen(WarehouseTask), 'The line still wants receiving.');

        WarehouseReceiptLine.Get('WHA-WR-05', 10000);
        WarehouseReceiptLine."Qty. Outstanding" := 0;
        WarehouseReceiptLine.Modify(false);

        Assert.IsFalse(TaskSourceMgt.SourceIsOpen(WarehouseTask), 'Nothing is outstanding any more, so nobody needs to walk it.');
    end;

    [Test]
    procedure AJobPutOnTheQueueByHandHasNoDocumentBehindIt()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] Segment 1 work still exists and still has to behave. A hand-made job has no document,
        // says so, and is nobody's to close but the warehouse's.
        ConfigureQueue(0);
        CreateWorkableTask(WarehouseTask, 'WHA-TASK-MANUAL');

        Assert.AreEqual(SourceType::WHAManual, WarehouseTask."Source Type", 'A job nobody raised from a document is a hand-made one.');
        Assert.AreEqual('', TaskSourceMgt.DescribeLink(WarehouseTask), 'There is no document to name.');
        Assert.IsTrue(TaskSourceMgt.SourceIsOpen(WarehouseTask), 'Nothing outside the app can finish it.');
        Assert.IsFalse(TaskSourceMgt.ShowSource(WarehouseTask), 'There is nothing to open.');
    end;

    [Test]
    procedure RaisingWorkFromADocumentThatIsNotThereIsRefused()
    var
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] Asking a document that does not exist for work is a mistake worth being told about,
        // not an empty answer that looks like a document with nothing on it.
        ConfigureQueue(0);
        EnsureTaskNumbering();

        asserterror TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-NOPE');

        Assert.ExpectedError('does not exist');
    end;

    [Test]
    procedure WorkWaitingOnTheFloorIsCountedForTheRoleCentre()
    var
        ActivitiesCue: Record "WHA Activities Cue";
        WarehouseTask: Record "WHA Warehouse Task";
        TaskActivityCues: Codeunit "WHA Task Activity Cues";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        Results: Dictionary of [Text, Text];
    begin
        // [SCENARIO] The first tile a warehouse manager looks at is work nobody has picked up. The count
        // is worked out in a background session, so what is asserted here is what that session returns.
        ConfigureQueue(0);
        EnableDirectedWork();
        CreateWorkableTask(WarehouseTask, 'WHA-CUE-01');
        TaskLogic.Release(WarehouseTask);

        TaskActivityCues.AddCounts(Results);

        Assert.AreEqual('1', Results.Get(Format(ActivitiesCue.FieldNo("WHA Tasks Waiting"))), 'One released job is one job waiting.');
    end;

    [Test]
    procedure AFeatureThatIsSwitchedOffContributesNoTiles()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskActivityCues: Codeunit "WHA Task Activity Cues";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        Results: Dictionary of [Text, Text];
    begin
        // [SCENARIO] The role centre is one page for the whole app. A feature nobody switched on must add
        // nothing to it — not a zero, but nothing at all, so its tiles never appear.
        ConfigureQueue(0);
        DisableDirectedWork();
        CreateWorkableTask(WarehouseTask, 'WHA-CUE-02');
        TaskLogic.Release(WarehouseTask);

        TaskActivityCues.AddCounts(Results);

        Assert.AreEqual(0, Results.Count(), 'A switched-off feature should not put a single count on the role centre.');
    end;

    [Test]
    procedure FinishingAPutAwayFillsInTheQuantityToReceive()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] The link used to run one way: work was raised from a document and finishing it told
        // the document nothing. This is the other direction, and it is the point at which the app stops
        // being an overlay and starts driving what Business Central will post.
        ConfigureQueue(0);
        ConfigureWriteBack(true);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WB-01', 'PO-9001');
        AddReceiptLine('WHA-WB-01', 10000, 10);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WB-01');

        FindTaskForSource(WarehouseTask, SourceType::WHAWhseReceipt, 'WHA-WB-01', 10000);
        WorkThrough(WarehouseTask);
        TaskLogic.Complete(WarehouseTask);

        WarehouseReceiptLine.Get('WHA-WB-01', 10000);
        Assert.AreEqual(10, WarehouseReceiptLine."Qty. to Receive", 'What was put away should be what the receipt is ready to receive.');
        Assert.IsTrue(WarehouseTask."Written Back", 'The job should record that it changed the document.');
    end;

    [Test]
    procedure TwoJobsAgainstOneLineAddUpRatherThanReplace()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseTask: Record "WHA Warehouse Task";
        FollowUpTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        ShortReason: Enum "WHA Whse. Short Reason";
    begin
        // [SCENARIO] A job finished short raises a follow-up, and both serve the same receipt line. If the
        // second wrote what it moved rather than adding it, the first four would vanish from the document.
        ConfigureQueue(0);
        ConfigureWriteBack(true);
        ConfigureFollowUp(true);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WB-02', 'PO-9002');
        AddReceiptLine('WHA-WB-02', 10000, 10);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WB-02');

        FindTaskForSource(WarehouseTask, SourceType::WHAWhseReceipt, 'WHA-WB-02', 10000);
        WorkThrough(WarehouseTask);
        TaskLogic.CompleteShort(WarehouseTask, 4, ShortReason::WHANotEnough);

        WarehouseReceiptLine.Get('WHA-WB-02', 10000);
        Assert.AreEqual(4, WarehouseReceiptLine."Qty. to Receive", 'Only what was actually put away should reach the document.');

        FollowUpTask.SetRange("Source Type", SourceType::WHAWhseReceipt);
        FollowUpTask.SetRange("Source No.", 'WHA-WB-02');
        FollowUpTask.SetRange(Status, FollowUpTask.Status::WHACreated);
        FollowUpTask.FindFirst();
        WorkThrough(FollowUpTask);
        TaskLogic.Complete(FollowUpTask);

        WarehouseReceiptLine.Get('WHA-WB-02', 10000);
        Assert.AreEqual(10, WarehouseReceiptLine."Qty. to Receive", 'The follow-up should add its six to the four already there.');
    end;

    [Test]
    procedure FinishingAPickFillsInTheQuantityToShip()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] The shipment side of the same thing. A picked line is a line ready to ship.
        ConfigureQueue(0);
        ConfigureWriteBack(true);
        EnsureTaskNumbering();
        CreateShipment('WHA-WB-03', 'SO-9003');
        AddShipmentLine('WHA-WB-03', 10000, 5);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseShipment, 'WHA-WB-03');

        FindTaskForSource(WarehouseTask, SourceType::WHAWhseShipment, 'WHA-WB-03', 10000);
        WorkThrough(WarehouseTask);
        TaskLogic.Complete(WarehouseTask);

        WarehouseShipmentLine.Get('WHA-WB-03', 10000);
        Assert.AreEqual(5, WarehouseShipmentLine."Qty. to Ship", 'What was picked should be what the shipment is ready to ship.');
    end;

    [Test]
    procedure TheDocumentIsLeftAloneWhenWritingBackIsOff()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] Off is the default and the behaviour this app has always had. Turning it on is a
        // decision about who owns the document, and nobody should find it made for them.
        ConfigureQueue(0);
        ConfigureWriteBack(false);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WB-04', 'PO-9004');
        AddReceiptLine('WHA-WB-04', 10000, 7);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WB-04');

        FindTaskForSource(WarehouseTask, SourceType::WHAWhseReceipt, 'WHA-WB-04', 10000);
        WorkThrough(WarehouseTask);
        TaskLogic.Complete(WarehouseTask);

        WarehouseReceiptLine.Get('WHA-WB-04', 10000);
        Assert.AreEqual(0, WarehouseReceiptLine."Qty. to Receive", 'The document should be untouched.');
        Assert.IsFalse(WarehouseTask."Written Back", 'And the job should not claim otherwise.');
    end;

    [Test]
    procedure WorkRaisedByHandChangesNoDocument()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] A hand-made job answers to no document, so writing back has nothing to write to and
        // must say so rather than failing.
        ConfigureQueue(0);
        ConfigureWriteBack(true);
        CreateStartedTask(WarehouseTask, 'WHA-WB-05', 3, CopyStr(UserId(), 1, 50));

        TaskLogic.Complete(WarehouseTask);

        Assert.IsFalse(WarehouseTask."Written Back", 'There was no document to change.');
    end;

    [Test]
    procedure AJobTakesTheLotFromAPalletHoldingOnlyOne()
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        // [SCENARIO] A pallet holding one lot of one item leaves no doubt what a job against it moves.
        // Taking the lot from it is reading a fact, not guessing: the alternative is a directed pick of a
        // tracked item that cannot say what it picked.
        ConfigureQueue(0);
        EnsureLocationAndBin();
        CreateUnitWithLot(HandlingUnit, HandlingUnitLine, 'WHA-TRK-HU-1', 'LOT-ONE', '');

        WarehouseTask.Init();
        WarehouseTask."No." := 'WHA-TRK-01';
        WarehouseTask."Location Code" := TestLocationTok;
        WarehouseTask."Handling Unit No." := HandlingUnit."No.";
        WarehouseTask."Item No." := CopyStr(TestItemTok, 1, 20);
        WarehouseTask.Quantity := 1;
        WarehouseTask.Insert(true);

        Assert.AreEqual('LOT-ONE', WarehouseTask."Lot No.", 'A pallet with one lot on it says which lot the job is for.');
    end;

    [Test]
    procedure AJobTakesNoLotFromAMixedPallet()
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        // [SCENARIO] Two lots of the same item on one pallet is exactly the case where guessing would be
        // wrong, and it is the case bin content has always been wrong about. The job is left blank for
        // somebody who can see the label to fill in.
        ConfigureQueue(0);
        EnsureLocationAndBin();
        CreateUnitWithLot(HandlingUnit, HandlingUnitLine, 'WHA-TRK-HU-2', 'LOT-A', '');
        AddUnitLine(HandlingUnit."No.", 20000, 'LOT-B', '');

        WarehouseTask.Init();
        WarehouseTask."No." := 'WHA-TRK-02';
        WarehouseTask."Location Code" := TestLocationTok;
        WarehouseTask."Handling Unit No." := HandlingUnit."No.";
        WarehouseTask."Item No." := CopyStr(TestItemTok, 1, 20);
        WarehouseTask.Quantity := 1;
        WarehouseTask.Insert(true);

        Assert.AreEqual('', WarehouseTask."Lot No.", 'A pallet holding two lots does not say which one the job is for.');
    end;

    [Test]
    procedure ALotAlreadyOnTheJobIsNotOverwritten()
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        // [SCENARIO] Whoever raised the work may know something the pallet does not — a partner system
        // asking for one lot out of a pallet it believes holds several. What they asked for wins.
        ConfigureQueue(0);
        EnsureLocationAndBin();
        CreateUnitWithLot(HandlingUnit, HandlingUnitLine, 'WHA-TRK-HU-3', 'LOT-FROM-UNIT', '');

        WarehouseTask.Init();
        WarehouseTask."No." := 'WHA-TRK-03';
        WarehouseTask."Location Code" := TestLocationTok;
        WarehouseTask."Handling Unit No." := HandlingUnit."No.";
        WarehouseTask."Item No." := CopyStr(TestItemTok, 1, 20);
        WarehouseTask."Lot No." := 'LOT-ASKED-FOR';
        WarehouseTask.Quantity := 1;
        WarehouseTask.Insert(true);

        Assert.AreEqual('LOT-ASKED-FOR', WarehouseTask."Lot No.", 'What the work asked for should survive.');
    end;

    [Test]
    procedure AJobWithNoPalletTakesNoLot()
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        // [SCENARIO] An item job with no pallet behind it has nothing to read a lot from, and must not
        // invent one. This is the case the register still calls open: the operator cannot yet say what
        // they picked, because nothing on the handheld asks them.
        ConfigureQueue(0);
        CreateWorkableTask(WarehouseTask, 'WHA-TRK-04');

        Assert.AreEqual('', WarehouseTask."Lot No.", 'There is nothing to take a lot from.');
        Assert.AreEqual('', WarehouseTask."Serial No.", 'And nothing to take a serial number from.');
    end;

    local procedure ConfigureQueue(MaxOpenTasks: Integer)
    var
        Setup: Record "WHA Warehouse Task Setup";
    begin
        EnsureTaskSetup(Setup);
        Setup.Validate("Default Priority", 100);
        Setup.Validate("Auto Release Tasks", false);
        Setup.Validate("Max Open Tasks Per User", MaxOpenTasks);
        Setup.Modify(true);
    end;

    local procedure ConfigureFollowUp(FollowUp: Boolean)
    var
        Setup: Record "WHA Warehouse Task Setup";
    begin
        EnsureTaskSetup(Setup);
        Setup.Validate("Follow Up Short Picks", FollowUp);
        Setup.Modify(true);
    end;

    local procedure CreateStartedTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20]; Qty: Decimal; OperatorId: Code[50])
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        CreateWorkableTask(WarehouseTask, TaskNo);
        WarehouseTask.Validate(Quantity, Qty);
        WarehouseTask.Modify(true);

        TaskLogic.Release(WarehouseTask);
        TaskLogic.Assign(WarehouseTask, OperatorId);
        TaskLogic.Start(WarehouseTask);
    end;

    local procedure EnsureTaskSetup(var Setup: Record "WHA Warehouse Task Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup.Insert(true);
    end;

    local procedure CreateWorkableTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20])
    begin
        EnsureLocationAndBin();

        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Location Code" := TestLocationTok;
        WarehouseTask."Item No." := 'TEST-ITEM';
        WarehouseTask.Quantity := 1;
        WarehouseTask.Insert(true);
    end;

    local procedure EnsureLocationAndBin()
    var
        Location: Record Location;
        Bin: Record Bin;
    begin
        if not Location.Get(TestLocationTok) then begin
            Location.Init();
            Location.Code := CopyStr(TestLocationTok, 1, MaxStrLen(Location.Code));
            Location.Insert();
        end;

        if Bin.Get(TestLocationTok, TestBinTok) then
            exit;

        Bin.Init();
        Bin."Location Code" := CopyStr(TestLocationTok, 1, MaxStrLen(Bin."Location Code"));
        Bin.Code := CopyStr(TestBinTok, 1, MaxStrLen(Bin.Code));
        Bin.Insert();
    end;

    local procedure EnsureUser(UserName: Code[50]): Code[50]
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserName);
        if not User.IsEmpty() then
            exit(UserName);

        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := UserName;
        User.Insert();
        exit(UserName);
    end;

    local procedure EnsureTaskNumbering()
    var
        Setup: Record "WHA Warehouse Task Setup";
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
    begin
        EnsureTaskSetup(Setup);
        if Setup."Warehouse Task Nos." <> '' then
            exit;

        Setup.Validate("Warehouse Task Nos.", NoSeriesMgt.EnsureSeries('WHA-TSTTASK', 'Warehouse advanced test tasks', 'WT000001', 'WT999999'));
        Setup.Modify(true);
    end;

    [Test]
    procedure WorkIsRefusedWhereBusinessCentralRaisesItsOwn()
    var
        Location: Record Location;
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] A location that requires Business Central's own put-away already raises a document
        // for these lines. Raising ours as well would send an operator to the same bin twice, so it is
        // refused rather than quietly doubled. See app/docs/location-configuration.md.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateReceipt('WHA-WR-BC', 'PO-1099');
        AddReceiptLine('WHA-WR-BC', 10000, 6);

        Location.Get(TestLocationTok);
        Location."Require Put-away" := true;
        Location.Modify(false);

        asserterror TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, 'WHA-WR-BC');

        Location."Require Put-away" := false;
        Location.Modify(false);

        Assert.ExpectedError('raises warehouse activities of its own');
    end;

    [Test]
    procedure APostingIsHeldWhileWorkIsStillOpen()
    var
        BlockOpenWork: Codeunit "WHA Block Open Work";
        SourceType: Enum "WHA Task Source";
        TaskStatus: Enum "WHA Warehouse Task Status";
    begin
        // [SCENARIO] Posting the document decides what Business Central believes was received. While a
        // job against it is still on the floor, that is not what the warehouse has done.
        CreateSourcedTask('WHA-OPEN-1', 'WHA-DOC-1', TaskStatus::WHAReleased);

        asserterror BlockOpenWork.Check(SourceType::WHAWhseReceipt, 'WHA-DOC-1');

        Assert.ExpectedError('nobody has finished or cancelled');
    end;

    [Test]
    procedure AFinishedDocumentIsLetThrough()
    var
        BlockOpenWork: Codeunit "WHA Block Open Work";
        SourceType: Enum "WHA Task Source";
        TaskStatus: Enum "WHA Warehouse Task Status";
    begin
        // [SCENARIO] Work that is done, and work somebody decided was not needed, are both answers. Only
        // an unanswered job holds the document.
        CreateSourcedTask('WHA-OPEN-2', 'WHA-DOC-2', TaskStatus::WHACompleted);
        CreateSourcedTask('WHA-OPEN-3', 'WHA-DOC-2', TaskStatus::WHACancelled);

        BlockOpenWork.Check(SourceType::WHAWhseReceipt, 'WHA-DOC-2');
    end;

    [Test]
    procedure ADocumentWithNoWorkAtAllIsLetThrough()
    var
        BlockOpenWork: Codeunit "WHA Block Open Work";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] A document this app was never asked about is none of its business.
        BlockOpenWork.Check(SourceType::WHAWhseReceipt, 'WHA-DOC-NONE');
        BlockOpenWork.Check(SourceType::WHAWhseReceipt, '');
    end;

    [Test]
    procedure OpenWorkOnAnotherDocumentHoldsNothing()
    var
        BlockOpenWork: Codeunit "WHA Block Open Work";
        SourceType: Enum "WHA Task Source";
        TaskStatus: Enum "WHA Warehouse Task Status";
    begin
        // [SCENARIO] The hold is per document, not per warehouse.
        CreateSourcedTask('WHA-OPEN-4', 'WHA-DOC-4', TaskStatus::WHAReleased);

        BlockOpenWork.Check(SourceType::WHAWhseReceipt, 'WHA-DOC-5');
    end;

    [Test]
    procedure LettingTheDocumentThroughHoldsNothingEver()
    var
        AllowOpenWork: Codeunit "WHA Allow Open Work";
        SourceType: Enum "WHA Task Source";
        TaskStatus: Enum "WHA Warehouse Task Status";
    begin
        // [SCENARIO] The value a fresh install and every upgrade lands on: the document posts, and this
        // app says nothing about it.
        CreateSourcedTask('WHA-OPEN-5', 'WHA-DOC-6', TaskStatus::WHAReleased);

        AllowOpenWork.Check(SourceType::WHAWhseReceipt, 'WHA-DOC-6');
    end;

    [Test]
    procedure EveryOpenWorkPolicyExplainsItself()
    var
        AllowOpenWork: Codeunit "WHA Allow Open Work";
        BlockOpenWork: Codeunit "WHA Block Open Work";
    begin
        // [SCENARIO] Setup shows what the choice does before a document is held or let through.
        Assert.AreNotEqual('', AllowOpenWork.Describe(), 'Letting the document through should still say so.');
        Assert.AreNotEqual('', BlockOpenWork.Describe(), 'Holding the document should say what it does.');
    end;

    [Test]
    procedure SomebodyWhoIsNotAWarehouseEmployeeCannotBeGivenWork()
    var
        WhseEmployeesOnly: Codeunit "WHA Whse. Employees Only";
    begin
        // [SCENARIO] With the restriction on, this app lets the same people work as Business Central's own
        // warehouse pages do, and refuses plainly rather than opening a dialog nobody on a handheld can
        // answer.
        EnsureUser('WHA-OUTSIDER');

        asserterror WhseEmployeesOnly.Check('WHA-OUTSIDER', CopyStr(TestLocationTok, 1, 10));

        Assert.ExpectedError('is not a warehouse employee at location');
    end;

    [Test]
    procedure SomebodyWithNoWarehouseAtAllCannotBeGivenWork()
    var
        WhseEmployeesOnly: Codeunit "WHA Whse. Employees Only";
    begin
        // [SCENARIO] A job that does not say where the work happens is checked against any location,
        // because somebody with no warehouse at all is wrong however the job ends up.
        EnsureUser('WHA-NOWHERE-EMP');

        asserterror WhseEmployeesOnly.Check('WHA-NOWHERE-EMP', '');

        Assert.ExpectedError('is not a warehouse employee at any location');
    end;

    [Test]
    procedure AWarehouseEmployeeCanBeGivenWorkThere()
    var
        WhseEmployeesOnly: Codeunit "WHA Whse. Employees Only";
    begin
        // [SCENARIO] The restriction refuses who it should and nobody else.
        EnsureLocationAndBin();
        EnsureWarehouseEmployee('WHA-INSIDER', CopyStr(TestLocationTok, 1, 10));

        WhseEmployeesOnly.Check('WHA-INSIDER', CopyStr(TestLocationTok, 1, 10));
        WhseEmployeesOnly.Check('WHA-INSIDER', '');
    end;

    [Test]
    procedure AWarehouseEmployeeSomewhereElseCannotBeGivenWorkHere()
    var
        WhseEmployeesOnly: Codeunit "WHA Whse. Employees Only";
    begin
        // [SCENARIO] The list is per location, not per person. Somebody who works the other warehouse is
        // not somebody who works this one.
        EnsureLocationAndBin();
        EnsureWarehouseEmployee('WHA-ELSEWHERE', 'WHA-OTHER');

        asserterror WhseEmployeesOnly.Check('WHA-ELSEWHERE', CopyStr(TestLocationTok, 1, 10));

        Assert.ExpectedError('is not a warehouse employee at location');
    end;

    [Test]
    procedure NobodyInParticularIsNotRefused()
    var
        WhseEmployeesOnly: Codeunit "WHA Whse. Employees Only";
    begin
        // [SCENARIO] Taking a job away from somebody leaves it assigned to nobody, and that is not a
        // person to check.
        WhseEmployeesOnly.Check('', CopyStr(TestLocationTok, 1, 10));
    end;

    [Test]
    procedure LettingAnybodyWorkRefusesNobody()
    var
        AnyUserWorks: Codeunit "WHA Any User Works";
    begin
        // [SCENARIO] The value a fresh install and every upgrade lands on: the warehouse employee list is
        // not consulted at all.
        AnyUserWorks.Check('WHA-OUTSIDER', CopyStr(TestLocationTok, 1, 10));
    end;

    [Test]
    procedure EveryAccessPolicyExplainsItself()
    var
        AnyUserWorks: Codeunit "WHA Any User Works";
        WhseEmployeesOnly: Codeunit "WHA Whse. Employees Only";
    begin
        // [SCENARIO] Setup shows who the choice lets work before anybody is refused a job.
        Assert.AreNotEqual('', AnyUserWorks.Describe(), 'Letting anybody work should still say so.');
        Assert.AreNotEqual('', WhseEmployeesOnly.Describe(), 'Restricting to warehouse employees should say what it does.');
    end;

    local procedure EnsureWarehouseEmployee(UserName: Code[50]; LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        EnsureUser(UserName);

        WarehouseEmployee.SetRange("User ID", UserName);
        WarehouseEmployee.SetRange("Location Code", LocationCode);
        if not WarehouseEmployee.IsEmpty() then
            exit;

        WarehouseEmployee.Init();
        WarehouseEmployee."User ID" := UserName;
        WarehouseEmployee."Location Code" := LocationCode;
        WarehouseEmployee.Insert(false);
    end;

    [Test]
    procedure AMovementWorksheetLineBecomesAMovement()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        // [SCENARIO] A movement worksheet line is already the shape of a warehouse task: a from-bin, a
        // to-bin, an item and a quantity. It should come across as a movement with both ends intact.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateMovementWorksheetLine('WHAMOVE', 10000, 5);

        Assert.AreEqual(1, TaskSourceMgt.GenerateFrom(SourceType::WHAMovementWksh, 'WHAMOVE'), 'The one outstanding line should have raised one job.');

        FindTaskForSource(WarehouseTask, SourceType::WHAMovementWksh, 'WHAMOVE', 10000);
        Assert.AreEqual(TaskType::WHAMovement, WarehouseTask."Task Type", 'A worksheet move is a movement.');
        Assert.AreEqual(5, WarehouseTask.Quantity, 'The job should ask for what is still outstanding.');
        Assert.AreEqual(CopyStr(TestBinTok, 1, 20), WarehouseTask."From Bin Code", 'A movement starts where the worksheet line takes from.');
        Assert.AreEqual('WHATEST-02', WarehouseTask."To Bin Code", 'A movement ends where the worksheet line puts into.');
    end;

    [Test]
    procedure AWorksheetLineAlreadyCoveredRaisesNothingTwice()
    var
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] Running it again should not double the queue, the same as every other source.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateMovementWorksheetLine('WHAMOVE2', 10000, 5);
        TaskSourceMgt.GenerateFrom(SourceType::WHAMovementWksh, 'WHAMOVE2');

        Assert.AreEqual(0, TaskSourceMgt.GenerateFrom(SourceType::WHAMovementWksh, 'WHAMOVE2'), 'Running it again should raise nothing.');
    end;

    [Test]
    procedure AWorksheetMoveIsNotWrittenBackWhileTheBinsAreNotMaintained()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        SrcMovementWksh: Codeunit "WHA Src Movement Wksh.";
    begin
        // [SCENARIO] Marking a worksheet line handled says the goods moved where Business Central can see
        // it. With registration off nothing moved there, and saying otherwise would be worse than the
        // duplication the write-back exists to prevent.
        ConfigureQueue(0);
        ConfigureNoRegistration();
        CreateMovementWorksheetLine('WHAMOVE3', 10000, 5);

        WarehouseTask.Init();
        WarehouseTask."Source No." := 'WHAMOVE3';
        WarehouseTask."Source Line No." := 10000;
        WarehouseTask."Location Code" := CopyStr(TestLocationTok, 1, 10);
        WarehouseTask."Quantity Handled" := 5;

        Assert.IsFalse(SrcMovementWksh.WriteBack(WarehouseTask), 'Nothing should be written back while the bins are not maintained.');
    end;

    local procedure ConfigureNoRegistration()
    var
        Setup: Record "WHA Warehouse Task Setup";
        Method: Enum "WHA Whse. Reg. Method";
    begin
        EnsureTaskSetup(Setup);
        Setup.Validate("Whse. Registration Method", Method::WHANone);
        Setup.Modify(true);
    end;

    local procedure CreateMovementWorksheetLine(WorksheetName: Code[10]; LineNo: Integer; Quantity: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        EnsureLocationAndBin();
        EnsureTestItem();
        EnsureSecondBin();

        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        if not WhseWorksheetTemplate.FindFirst() then begin
            WhseWorksheetTemplate.Init();
            WhseWorksheetTemplate.Name := 'WHAMVT';
            WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
            WhseWorksheetTemplate.Insert(false);
        end;

        WhseWorksheetLine.Init();
        WhseWorksheetLine."Worksheet Template Name" := WhseWorksheetTemplate.Name;
        WhseWorksheetLine.Name := WorksheetName;
        WhseWorksheetLine."Location Code" := CopyStr(TestLocationTok, 1, 10);
        WhseWorksheetLine."Line No." := LineNo;
        WhseWorksheetLine."Item No." := CopyStr(TestItemTok, 1, 20);
        WhseWorksheetLine."From Bin Code" := CopyStr(TestBinTok, 1, 20);
        WhseWorksheetLine."To Bin Code" := 'WHATEST-02';
        WhseWorksheetLine.Quantity := Quantity;
        WhseWorksheetLine."Qty. Outstanding" := Quantity;
        WhseWorksheetLine.Insert(false);
    end;

    local procedure EnsureSecondBin()
    var
        Bin: Record Bin;
    begin
        if Bin.Get(TestLocationTok, 'WHATEST-02') then
            exit;

        Bin.Init();
        Bin."Location Code" := CopyStr(TestLocationTok, 1, 10);
        Bin.Code := 'WHATEST-02';
        Bin.Insert();
    end;

    [Test]
    procedure AWarehouseActivityPairBecomesOneJobWithBothEnds()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        // [SCENARIO] Business Central splits a movement into a take from one bin and a place into another.
        // One job is that pair, not two jobs, and it carries both ends — which no document source can give.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateActivityPair('WHA-ACT-01', 3);

        Assert.AreEqual(1, TaskSourceMgt.GenerateFrom(SourceType::WHAWhseActivity, 'WHA-ACT-01'), 'A take and its place are one job.');

        FindTaskForSource(WarehouseTask, SourceType::WHAWhseActivity, 'WHA-ACT-01', 10000);
        Assert.AreEqual(TaskType::WHAMovement, WarehouseTask."Task Type", 'A movement activity becomes a movement.');
        Assert.AreEqual(CopyStr(TestBinTok, 1, 20), WarehouseTask."From Bin Code", 'The job starts at the take line''s bin.');
        Assert.AreEqual('WHATEST-02', WarehouseTask."To Bin Code", 'The job ends at the place line''s bin.');
        Assert.AreEqual(3, WarehouseTask.Quantity, 'The job asks for what the activity still wants handled.');
    end;

    [Test]
    procedure AnActivityAlreadyOnTheQueueIsNotRaisedTwice()
    var
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] The same rule every other source follows.
        ConfigureQueue(0);
        EnsureTaskNumbering();
        CreateActivityPair('WHA-ACT-02', 3);
        TaskSourceMgt.GenerateFrom(SourceType::WHAWhseActivity, 'WHA-ACT-02');

        Assert.AreEqual(0, TaskSourceMgt.GenerateFrom(SourceType::WHAWhseActivity, 'WHA-ACT-02'), 'Running it again should raise nothing.');
    end;

    [Test]
    procedure TwoKindsOfActivitySharingANumberAreRefused()
    var
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] An activity is identified by its kind and its number, and a task has room for one
        // code. Business Central numbers each kind separately so this is rare — and rare is not a reason
        // to guess when the answer decides which stock moves.
        ConfigureQueue(0);
        CreateActivityPair('WHA-ACT-03', 3);
        AddActivityLine('WHA-ACT-03', 30000, ActivityTypePick(), ActionTake(), CopyStr(TestBinTok, 1, 20), 1);

        asserterror TaskSourceMgt.GenerateFrom(SourceType::WHAWhseActivity, 'WHA-ACT-03');

        Assert.ExpectedError('More than one kind of warehouse activity');
    end;

    [Test]
    procedure AnActivityNobodyRaisedIsRefused()
    var
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        // [SCENARIO] Asking for work from an activity that does not exist is a mistake, not an empty queue.
        asserterror TaskSourceMgt.GenerateFrom(SourceType::WHAWhseActivity, 'WHA-ACT-NONE');

        Assert.ExpectedError('has no lines');
    end;

    local procedure ActivityTypeMovement(): Enum "Warehouse Activity Type"
    var
        ActivityType: Enum "Warehouse Activity Type";
    begin
        exit(ActivityType::Movement);
    end;

    local procedure ActivityTypePick(): Enum "Warehouse Activity Type"
    var
        ActivityType: Enum "Warehouse Activity Type";
    begin
        exit(ActivityType::Pick);
    end;

    local procedure ActionTake(): Enum "Warehouse Action Type"
    var
        ActionType: Enum "Warehouse Action Type";
    begin
        exit(ActionType::Take);
    end;

    local procedure ActionPlace(): Enum "Warehouse Action Type"
    var
        ActionType: Enum "Warehouse Action Type";
    begin
        exit(ActionType::Place);
    end;

    local procedure CreateActivityPair(ActivityNo: Code[20]; Quantity: Decimal)
    begin
        EnsureLocationAndBin();
        EnsureTestItem();
        EnsureSecondBin();
        AddActivityLine(ActivityNo, 10000, ActivityTypeMovement(), ActionTake(), CopyStr(TestBinTok, 1, 20), Quantity);
        AddActivityLine(ActivityNo, 20000, ActivityTypeMovement(), ActionPlace(), 'WHATEST-02', Quantity);
    end;

    local procedure AddActivityLine(ActivityNo: Code[20]; LineNo: Integer; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.Init();
        WarehouseActivityLine."Activity Type" := ActivityType;
        WarehouseActivityLine."No." := ActivityNo;
        WarehouseActivityLine."Line No." := LineNo;
        WarehouseActivityLine."Action Type" := ActionType;
        WarehouseActivityLine."Location Code" := CopyStr(TestLocationTok, 1, 10);
        WarehouseActivityLine."Bin Code" := BinCode;
        WarehouseActivityLine."Item No." := CopyStr(TestItemTok, 1, 20);
        WarehouseActivityLine.Quantity := Quantity;
        WarehouseActivityLine."Qty. Outstanding" := Quantity;
        WarehouseActivityLine.Insert(false);
    end;

    local procedure CreateSourcedTask(TaskNo: Code[20]; SourceNo: Code[20]; NewStatus: Enum "WHA Warehouse Task Status")
    var
        WarehouseTask: Record "WHA Warehouse Task";
        SourceType: Enum "WHA Task Source";
    begin
        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Source Type" := SourceType::WHAWhseReceipt;
        WarehouseTask."Source No." := SourceNo;
        WarehouseTask."Source Line No." := 10000;
        WarehouseTask.Status := NewStatus;
        WarehouseTask.Insert(false);
    end;

    local procedure CreateReceipt(ReceiptNo: Code[20]; OrderNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        EnsureLocationAndBin();
        EnsureTestItem();

        if WarehouseReceiptHeader.Get(ReceiptNo) then
            exit;

        WarehouseReceiptHeader.Init();
        WarehouseReceiptHeader."No." := ReceiptNo;
        WarehouseReceiptHeader."Location Code" := CopyStr(TestLocationTok, 1, 10);
        WarehouseReceiptHeader.Insert(false);

        LastOrderNo := OrderNo;
    end;

    local procedure AddReceiptLine(ReceiptNo: Code[20]; LineNo: Integer; Outstanding: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.Init();
        WarehouseReceiptLine."No." := ReceiptNo;
        WarehouseReceiptLine."Line No." := LineNo;
        WarehouseReceiptLine."Location Code" := CopyStr(TestLocationTok, 1, 10);
        WarehouseReceiptLine."Bin Code" := CopyStr(TestBinTok, 1, 20);
        WarehouseReceiptLine."Item No." := CopyStr(TestItemTok, 1, 20);
        WarehouseReceiptLine.Quantity := Outstanding;
        WarehouseReceiptLine."Qty. Outstanding" := Outstanding;
        WarehouseReceiptLine."Source No." := LastOrderNo;
        WarehouseReceiptLine.Insert(false);
    end;

    local procedure CreateShipment(ShipmentNo: Code[20]; OrderNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        EnsureLocationAndBin();
        EnsureTestItem();

        if WarehouseShipmentHeader.Get(ShipmentNo) then
            exit;

        WarehouseShipmentHeader.Init();
        WarehouseShipmentHeader."No." := ShipmentNo;
        WarehouseShipmentHeader."Location Code" := CopyStr(TestLocationTok, 1, 10);
        WarehouseShipmentHeader.Insert(false);

        LastOrderNo := OrderNo;
    end;

    local procedure AddShipmentLine(ShipmentNo: Code[20]; LineNo: Integer; Outstanding: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.Init();
        WarehouseShipmentLine."No." := ShipmentNo;
        WarehouseShipmentLine."Line No." := LineNo;
        WarehouseShipmentLine."Location Code" := CopyStr(TestLocationTok, 1, 10);
        WarehouseShipmentLine."Bin Code" := CopyStr(TestBinTok, 1, 20);
        WarehouseShipmentLine."Item No." := CopyStr(TestItemTok, 1, 20);
        WarehouseShipmentLine.Quantity := Outstanding;
        WarehouseShipmentLine."Qty. Outstanding" := Outstanding;
        WarehouseShipmentLine."Source No." := LastOrderNo;
        WarehouseShipmentLine.Insert(false);
    end;

    local procedure FindTaskForSource(var WarehouseTask: Record "WHA Warehouse Task"; SourceType: Enum "WHA Task Source"; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        WarehouseTask.Reset();
        WarehouseTask.SetRange("Source Type", SourceType);
        WarehouseTask.SetRange("Source No.", SourceNo);
        WarehouseTask.SetRange("Source Line No.", SourceLineNo);
        WarehouseTask.SetFilter(Status, '<>%1', WarehouseTask.Status::WHACancelled);
        WarehouseTask.FindFirst();
    end;

    local procedure EnsureTestItem()
    var
        Item: Record Item;
    begin
        if Item.Get(CopyStr(TestItemTok, 1, 20)) then
            exit;

        Item.Init();
        Item."No." := CopyStr(TestItemTok, 1, 20);
        Item.Insert(true);
    end;

    local procedure EnableDirectedWork()
    begin
        SetDirectedWorkEnabled(true);
    end;

    local procedure DisableDirectedWork()
    begin
        SetDirectedWorkEnabled(false);
    end;

    local procedure SetDirectedWorkEnabled(Enabled: Boolean)
    var
        Setup: Record "WHA Warehouse Task Setup";
    begin
        Setup.Get();
        Setup."WHA Enabled" := Enabled;
        Setup.Modify(true);
    end;

    local procedure ConfigureWriteBack(WriteBack: Boolean)
    var
        Setup: Record "WHA Warehouse Task Setup";
    begin
        EnsureTaskSetup(Setup);
        Setup.Validate("Write Back To Document", WriteBack);
        Setup.Modify(true);
    end;

    local procedure WorkThrough(var WarehouseTask: Record "WHA Warehouse Task")
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if WarehouseTask.Status = WarehouseTask.Status::WHACreated then
            TaskLogic.Release(WarehouseTask);
        TaskLogic.Assign(WarehouseTask, CopyStr(UserId(), 1, MaxStrLen(WarehouseTask."Assigned To User ID")));
        TaskLogic.Start(WarehouseTask);
    end;


    local procedure CreateUnitWithLot(var HandlingUnit: Record "WHA Handling Unit"; var HandlingUnitLine: Record "WHA Handling Unit Line"; UnitNo: Code[20]; LotNo: Code[50]; SerialNo: Code[50])
    begin
        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit."Location Code" := TestLocationTok;
        HandlingUnit.Insert(true);

        AddUnitLine(UnitNo, 10000, LotNo, SerialNo);
        HandlingUnitLine.Get(UnitNo, 10000);
    end;

    local procedure AddUnitLine(UnitNo: Code[20]; LineNo: Integer; LotNo: Code[50]; SerialNo: Code[50])
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Line No." := LineNo;
        HandlingUnitLine."Item No." := CopyStr(TestItemTok, 1, 20);
        HandlingUnitLine."Lot No." := LotNo;
        HandlingUnitLine."Serial No." := SerialNo;
        HandlingUnitLine.Quantity := 1;
        HandlingUnitLine.Insert(true);
    end;

}
