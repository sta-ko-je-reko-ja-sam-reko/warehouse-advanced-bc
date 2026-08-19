codeunit 51001 "WHA Warehouse Task Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLocationTok: Label 'WHATEST', Locked = true;
        TestBinTok: Label 'WHATEST-01', Locked = true;

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
}
