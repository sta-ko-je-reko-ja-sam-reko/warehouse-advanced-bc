codeunit 51004 "WHA Wave Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHAWAVE', Locked = true;
        OtherLocationTok: Label 'WHAWAVE2', Locked = true;

    [Test]
    procedure FillingGathersTheMostUrgentWorkFirst()
    var
        Wave: Record "WHA Wave";
        UrgentTask: Record "WHA Warehouse Task";
        RoutineTask: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] A wave gathers the work the queue would have handed out next, so that filling a wave
        // never changes what gets done — only when it goes out.
        ConfigureWaves(false);
        CreateReleasedTask(RoutineTask, 'WV-ROUTINE', CopyStr(LocationTok, 1, 10), 90);
        CreateReleasedTask(UrgentTask, 'WV-URGENT', CopyStr(LocationTok, 1, 10), 5);
        CreateWave(Wave, 'WV-FILL-1', CopyStr(LocationTok, 1, 10), 1);

        Assert.AreEqual(1, WaveLogic.Fill(Wave), 'The wave should have taken one job.');

        UrgentTask.Get('WV-URGENT');
        RoutineTask.Get('WV-ROUTINE');
        Assert.AreEqual('WV-FILL-1', UrgentTask."Wave No.", 'The most urgent job should be the one gathered.');
        Assert.AreEqual('', RoutineTask."Wave No.", 'The routine job should have been left where it was.');
    end;

    [Test]
    procedure FillingStopsAtTheMaxJobCount()
    var
        Wave: Record "WHA Wave";
        FirstTask: Record "WHA Warehouse Task";
        SecondTask: Record "WHA Warehouse Task";
        ThirdTask: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] A wave bigger than a shift can finish is a wave nobody trusts, so the cap is real.
        ConfigureWaves(false);
        CreateReleasedTask(FirstTask, 'WV-CAP-1', CopyStr(LocationTok, 1, 10), 10);
        CreateReleasedTask(SecondTask, 'WV-CAP-2', CopyStr(LocationTok, 1, 10), 20);
        CreateReleasedTask(ThirdTask, 'WV-CAP-3', CopyStr(LocationTok, 1, 10), 30);
        CreateWave(Wave, 'WV-CAP', CopyStr(LocationTok, 1, 10), 2);

        Assert.AreEqual(2, WaveLogic.Fill(Wave), 'The wave should stop at its maximum.');

        Assert.AreEqual(0, WaveLogic.Fill(Wave), 'A full wave should gather nothing more.');
    end;

    [Test]
    procedure FillingIgnoresWorkAtOtherLocations()
    var
        Wave: Record "WHA Wave";
        ElsewhereTask: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] A wave belongs to a part of the warehouse. Work at the other end is not its business,
        // however urgent it is.
        ConfigureWaves(false);
        CreateReleasedTask(ElsewhereTask, 'WV-ELSEWHERE', CopyStr(OtherLocationTok, 1, 10), 1);
        CreateWave(Wave, 'WV-LOCAL', CopyStr(LocationTok, 1, 10), 10);

        Assert.AreEqual(0, WaveLogic.Fill(Wave), 'A wave should not gather work from another location.');
    end;

    [Test]
    procedure FillingLeavesDraftWorkAloneByDefault()
    var
        Wave: Record "WHA Wave";
        DraftTask: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] Work nobody has approved for the floor is not swept into a wave behind their back.
        ConfigureWaves(false);
        CreateDraftTask(DraftTask, 'WV-DRAFT', CopyStr(LocationTok, 1, 10));
        CreateWave(Wave, 'WV-NODRAFT', CopyStr(LocationTok, 1, 10), 10);

        Assert.AreEqual(0, WaveLogic.Fill(Wave), 'A draft job should not be gathered by default.');
    end;

    [Test]
    procedure DraftWorkCanBeGatheredWhenTheSetupAllowsIt()
    var
        Wave: Record "WHA Wave";
        DraftTask: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] A warehouse that plans in waves wants the wave to be the approval, so the setup can
        // let drafts in — and releasing the wave is then what sends them to the floor.
        ConfigureWaves(true);
        CreateDraftTask(DraftTask, 'WV-DRAFT-OK', CopyStr(LocationTok, 1, 10));
        CreateWave(Wave, 'WV-WITHDRAFT', CopyStr(LocationTok, 1, 10), 10);

        Assert.AreEqual(1, WaveLogic.Fill(Wave), 'A draft job should be gathered when the setup allows it.');
    end;

    [Test]
    procedure ReleasingAWaveSendsItsDraftsToTheFloor()
    var
        Wave: Record "WHA Wave";
        DraftTask: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] This is what a wave is for: the work becomes available together rather than
        // trickling out one job at a time.
        ConfigureWaves(true);
        CreateDraftTask(DraftTask, 'WV-REL-DRAFT', CopyStr(LocationTok, 1, 10));
        CreateWave(Wave, 'WV-RELEASE', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(Wave);

        WaveLogic.Release(Wave);

        DraftTask.Get('WV-REL-DRAFT');
        Assert.AreEqual(DraftTask.Status::WHAReleased, DraftTask.Status, 'Releasing the wave should release its work.');
        Assert.AreEqual(Wave.Status::WHAReleased, Wave.Status, 'The wave itself should be released.');
        Assert.IsTrue(Wave."Released At" <> 0DT, 'Releasing should record when it happened.');
    end;

    [Test]
    procedure AnEmptyWaveCannotBeReleased()
    var
        Wave: Record "WHA Wave";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] Releasing nothing looks like success and is not.
        ConfigureWaves(false);
        CreateWave(Wave, 'WV-EMPTY', CopyStr(LocationTok, 1, 10), 10);

        asserterror WaveLogic.Release(Wave);

        Assert.ExpectedError('holds no work');
    end;

    [Test]
    procedure AReleasedWaveCannotBeChanged()
    var
        Wave: Record "WHA Wave";
        Task: Record "WHA Warehouse Task";
        OtherTask: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] Once the work is on the floor, adding to the wave would change what people are
        // already doing.
        ConfigureWaves(false);
        CreateReleasedTask(Task, 'WV-LOCKED-1', CopyStr(LocationTok, 1, 10), 10);
        CreateWave(Wave, 'WV-LOCKED', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(Wave);
        WaveLogic.Release(Wave);

        CreateReleasedTask(OtherTask, 'WV-LOCKED-2', CopyStr(LocationTok, 1, 10), 10);

        asserterror WaveLogic.AddTask(Wave, OtherTask);

        Assert.ExpectedError('can no longer be changed');
    end;

    [Test]
    procedure WorkAlreadyInAWaveIsNotTakenByAnother()
    var
        FirstWave: Record "WHA Wave";
        SecondWave: Record "WHA Wave";
        Task: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] Two waves claiming the same job is two people being sent to do it.
        ConfigureWaves(false);
        CreateReleasedTask(Task, 'WV-SHARED', CopyStr(LocationTok, 1, 10), 10);
        CreateWave(FirstWave, 'WV-FIRST', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(FirstWave);

        CreateWave(SecondWave, 'WV-SECOND', CopyStr(LocationTok, 1, 10), 10);

        Assert.AreEqual(0, WaveLogic.Fill(SecondWave), 'Work already in a wave should not be gathered again.');

        Task.Get('WV-SHARED');
        asserterror WaveLogic.AddTask(SecondWave, Task);
        Assert.ExpectedError('already in wave');
    end;

    [Test]
    procedure TakingWorkOutOfAWaveLeavesTheJobAlone()
    var
        Wave: Record "WHA Wave";
        Task: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] A job pulled out of a wave is still a job. Only its membership changes.
        ConfigureWaves(false);
        CreateReleasedTask(Task, 'WV-PULLOUT', CopyStr(LocationTok, 1, 10), 10);
        CreateWave(Wave, 'WV-PULL', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(Wave);
        Task.Get('WV-PULLOUT');

        WaveLogic.RemoveTask(Wave, Task);

        Task.Get('WV-PULLOUT');
        Assert.AreEqual('', Task."Wave No.", 'The job should no longer be in the wave.');
        Assert.AreEqual(Task.Status::WHAReleased, Task.Status, 'The job itself should be untouched.');
    end;

    [Test]
    procedure AWaveWithWorkOutstandingCannotBeCompleted()
    var
        Wave: Record "WHA Wave";
        Task: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] A wave is finished when its work is, not when somebody says so.
        ConfigureWaves(false);
        CreateReleasedTask(Task, 'WV-OUTSTANDING', CopyStr(LocationTok, 1, 10), 10);
        CreateWave(Wave, 'WV-UNFINISHED', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(Wave);
        WaveLogic.Release(Wave);

        asserterror WaveLogic.Complete(Wave);

        Assert.ExpectedError('outstanding');
    end;

    [Test]
    procedure AWaveClosesWhenItsWorkIsDone()
    var
        Wave: Record "WHA Wave";
        Task: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] Nothing pushes a finished job back to its wave, so the wave is closed by asking. The
        // answer has to be right when it is asked.
        ConfigureWaves(false);
        CreateReleasedTask(Task, 'WV-DONE-TASK', CopyStr(LocationTok, 1, 10), 10);
        CreateWave(Wave, 'WV-DONE', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(Wave);
        WaveLogic.Release(Wave);

        Task.Get('WV-DONE-TASK');
        Task.Status := Task.Status::WHACompleted;
        Task.Modify(true);

        Assert.IsTrue(WaveLogic.CompleteIfFinished(Wave), 'A wave whose work is done should close.');
        Assert.AreEqual(Wave.Status::WHACompleted, Wave.Status, 'The wave should be completed.');
        Assert.IsTrue(Wave."Completed At" <> 0DT, 'Closing should record when it happened.');
    end;

    [Test]
    procedure CancellingAWaveWithdrawsWorkNobodyStarted()
    var
        Wave: Record "WHA Wave";
        Task: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] Withdrawing a wave withdraws what it put on the floor, or the jobs outlive the
        // reason they existed.
        ConfigureWaves(false);
        CreateReleasedTask(Task, 'WV-CANCEL-TASK', CopyStr(LocationTok, 1, 10), 10);
        CreateWave(Wave, 'WV-CANCEL', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(Wave);

        WaveLogic.Cancel(Wave);

        Task.Get('WV-CANCEL-TASK');
        Assert.AreEqual(Task.Status::WHACancelled, Task.Status, 'Cancelling a wave should withdraw its unstarted work.');
        Assert.AreEqual(Wave.Status::WHACancelled, Wave.Status, 'The wave should be cancelled.');
    end;

    [Test]
    procedure DeletingAnOpenWaveFreesItsWork()
    var
        Wave: Record "WHA Wave";
        Task: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] A deleted wave must not leave jobs pointing at something that no longer exists —
        // they would be invisible to every other wave for ever.
        ConfigureWaves(false);
        CreateReleasedTask(Task, 'WV-FREED', CopyStr(LocationTok, 1, 10), 10);
        CreateWave(Wave, 'WV-DELETE', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(Wave);

        Wave.Delete(true);

        Task.Get('WV-FREED');
        Assert.AreEqual('', Task."Wave No.", 'Deleting a wave should free its work.');
        Assert.AreEqual(Task.Status::WHAReleased, Task.Status, 'The freed job should still be available.');
    end;

    [Test]
    procedure AReleasedWaveCannotBeDeleted()
    var
        Wave: Record "WHA Wave";
        Task: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] What was planned and sent to the floor is a record, not a draft.
        ConfigureWaves(false);
        CreateReleasedTask(Task, 'WV-KEPT-TASK', CopyStr(LocationTok, 1, 10), 10);
        CreateWave(Wave, 'WV-KEPT', CopyStr(LocationTok, 1, 10), 10);
        WaveLogic.Fill(Wave);
        WaveLogic.Release(Wave);

        asserterror Wave.Delete(true);

        Assert.ExpectedError('Cancel it instead');
    end;

    [Test]
    procedure TheDueStrategyIgnoresPriority()
    var
        Wave: Record "WHA Wave";
        UrgentLateTask: Record "WHA Warehouse Task";
        RoutineSoonTask: Record "WHA Warehouse Task";
        WaveLogic: Codeunit "WHA Wave Logic";
        Strategy: Enum "WHA Wave Strategy";
    begin
        // [SCENARIO] A warehouse shipping to a departure time cares what leaves at four o'clock, not what
        // somebody marked urgent. Choosing the strategy changes which work a wave takes.
        ConfigureWaves(false);
        CreateReleasedTask(UrgentLateTask, 'WV-URGENT-LATE', CopyStr(LocationTok, 1, 10), 1);
        UrgentLateTask.Validate("Due Date", CalcDate('<+7D>', WorkDate()));
        UrgentLateTask.Modify(true);

        CreateReleasedTask(RoutineSoonTask, 'WV-ROUTINE-SOON', CopyStr(LocationTok, 1, 10), 99);
        RoutineSoonTask.Validate("Due Date", WorkDate());
        RoutineSoonTask.Modify(true);

        CreateWave(Wave, 'WV-DUE', CopyStr(LocationTok, 1, 10), 1);
        Wave.Validate(Strategy, Strategy::WHADueFirst);
        Wave.Modify(true);

        WaveLogic.Fill(Wave);

        RoutineSoonTask.Get('WV-ROUTINE-SOON');
        Assert.AreEqual('WV-DUE', RoutineSoonTask."Wave No.", 'The due-first strategy should take the job due soonest.');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        Wave: Record "WHA Wave";
        DemoWave: Codeunit "WHA Demo Wave";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice creates the waves once.
        DemoWave.Import();
        Wave.SetFilter("No.", 'DEMO-WAVE-*');
        CountAfterFirstRun := Wave.Count();

        DemoWave.Import();

        Assert.AreEqual(3, CountAfterFirstRun, 'The first import should create three sample waves.');
        Assert.AreEqual(CountAfterFirstRun, Wave.Count(), 'A second import should not create more waves.');
    end;

    local procedure ConfigureWaves(IncludeUnreleased: Boolean)
    var
        Setup: Record "WHA Wave Setup";
        TaskSetup: Record "WHA Warehouse Task Setup";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        Setup.Validate("Include Unreleased Work", IncludeUnreleased);
        Setup.Validate("Default Max Tasks", 25);
        Setup.Modify(true);

        TaskSetup.Reset();
        if not TaskSetup.Get() then begin
            TaskSetup.Init();
            TaskSetup.Insert(true);
        end;
        TaskSetup.Validate("Auto Release Tasks", false);
        TaskSetup.Modify(true);

        EnsureLocation(LocationTok);
        EnsureLocation(OtherLocationTok);
    end;

    local procedure CreateWave(var Wave: Record "WHA Wave"; WaveNo: Code[20]; LocationCode: Code[10]; MaxTasks: Integer)
    begin
        Wave.Init();
        Wave."No." := WaveNo;
        Wave."Location Code" := LocationCode;
        Wave."Max Tasks" := MaxTasks;
        Wave.Insert(true);
    end;

    local procedure CreateDraftTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Location Code" := LocationCode;
        WarehouseTask."Item No." := 'WV-ITEM';
        WarehouseTask.Quantity := 1;
        WarehouseTask.Insert(true);
    end;

    local procedure CreateReleasedTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20]; LocationCode: Code[10]; TaskPriority: Integer)
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        CreateDraftTask(WarehouseTask, TaskNo, LocationCode);
        WarehouseTask.Priority := TaskPriority;
        WarehouseTask.Modify(true);

        TaskLogic.Release(WarehouseTask);
    end;

    local procedure EnsureLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            exit;

        Location.Init();
        Location.Code := LocationCode;
        Location.Insert();
    end;
}
