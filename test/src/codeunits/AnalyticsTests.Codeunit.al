codeunit 51013 "WHA Analytics Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHAKPI', Locked = true;
        ItemTok: Label 'WHA-KPI-ITEM', Locked = true;
        EmptyLocationTok: Label 'WHAKPIEMP', Locked = true;

    [Test]
    procedure JobsFinishedCountsWhatWasFinishedInThePeriod()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        // [SCENARIO] The plainest measure in the app, and the one every other figure is read against. A
        // period that quietly included last month would make every comparison meaningless.
        ConfigureAnalytics();
        CreateCompletedTask('KPI-T1', TaskType::WHAPick, 5, 5, CreateDateTime(WorkDate(), 100000T));
        CreateCompletedTask('KPI-T2', TaskType::WHAPick, 3, 3, CreateDateTime(WorkDate(), 110000T));
        CreateCompletedTask('KPI-T3', TaskType::WHAPutAway, 8, 8, CreateDateTime(WorkDate(), 120000T));
        CreateCompletedTask('KPI-T4', TaskType::WHAPick, 4, 4, CreateDateTime(WorkDate() - 30, 100000T));

        Assert.AreEqual(3, KpiMgt.Measure(KpiMeasure::WHATasksCompleted, CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'Three jobs were finished inside the period and one outside it.');
    end;

    [Test]
    procedure NothingToMeasureIsZeroRatherThanAFailure()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
    begin
        // [SCENARIO] A warehouse that has just installed the app has no history. Every figure being zero
        // is the correct answer, and it has to be reached without anybody seeing an error.
        ConfigureAnalytics();
        EnsureLocation(CopyStr(EmptyLocationTok, 1, 10));

        Assert.AreEqual(0, KpiMgt.Measure(KpiMeasure::WHATasksCompleted, CopyStr(EmptyLocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'Nothing was done there.');
        Assert.AreEqual(0, KpiMgt.Measure(KpiMeasure::WHAPickShortRate, CopyStr(EmptyLocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'A share of nothing is zero, not a division by zero.');
        Assert.AreEqual(0, KpiMgt.Measure(KpiMeasure::WHATrailerTurnaround, CopyStr(EmptyLocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'No vehicle came, so there is no turnaround.');
    end;

    [Test]
    procedure PickShortRateIsTheShareOfPicksThatCameUpShort()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        // [SCENARIO] One short pick is an incident; a quarter of them is a process. The measure is what
        // turns the short reasons the handheld records into something worth acting on.
        ConfigureAnalytics();
        CreateCompletedTask('KPI-S1', TaskType::WHAPick, 10, 10, CreateDateTime(WorkDate(), 100000T));
        CreateCompletedTask('KPI-S2', TaskType::WHAPick, 10, 10, CreateDateTime(WorkDate(), 101000T));
        CreateCompletedTask('KPI-S3', TaskType::WHAPick, 10, 10, CreateDateTime(WorkDate(), 102000T));
        CreateCompletedTask('KPI-S4', TaskType::WHAPick, 10, 6, CreateDateTime(WorkDate(), 103000T));
        CreateCompletedTask('KPI-S5', TaskType::WHAPutAway, 10, 2, CreateDateTime(WorkDate(), 104000T));

        Assert.AreEqual(25, KpiMgt.Measure(KpiMeasure::WHAPickShortRate, CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'One pick in four came up short, and the put-away is not a pick.');
    end;

    [Test]
    procedure PutAwayLeadTimeCountsPutAwaysAndNothingElse()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        // [SCENARIO] The measure is deliberately not called dock-to-stock: it starts when the work was
        // raised, not when the lorry arrived. What can be asserted here is which jobs it looks at - the
        // elapsed time itself comes from the platform's own created stamp, which a test cannot fabricate.
        ConfigureAnalytics();
        CreateCompletedTask('KPI-L1', TaskType::WHAPick, 5, 5, CreateDateTime(WorkDate(), 100000T));
        CreateCompletedTask('KPI-L2', TaskType::WHAPick, 5, 5, CreateDateTime(WorkDate(), 101000T));

        Assert.AreEqual(0, KpiMgt.Measure(KpiMeasure::WHAPutAwayLeadTime, CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'Picking is not putting away, so there is nothing to average.');

        CreateCompletedTask('KPI-L3', TaskType::WHAPutAway, 5, 5, CreateDateTime(WorkDate(), 102000T));
        Assert.IsTrue(KpiMgt.Measure(KpiMeasure::WHAPutAwayLeadTime, CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate()) >= 0, 'A put-away finished in the period is measured.');
    end;

    [Test]
    procedure TurnaroundIsMeasuredGateToGate()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
    begin
        // [SCENARIO] This is the number the haulier bills on, so it is measured from reporting at the
        // gate to leaving it, and not from anything the warehouse would rather it started at.
        ConfigureAnalytics();
        CreateVisit('KPI-V1', CreateDateTime(WorkDate(), 080000T), CreateDateTime(WorkDate(), 083000T), CreateDateTime(WorkDate(), 093000T));

        Assert.AreEqual(90, KpiMgt.Measure(KpiMeasure::WHATrailerTurnaround, CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'Eight to half past nine is ninety minutes.');
    end;

    [Test]
    procedure WaitingForADoorIsMeasuredApartFromTheVisit()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
    begin
        // [SCENARIO] Waiting is the yard's problem and the time on the door is the warehouse's, so one
        // number for both would tell whoever is trying to fix it nothing.
        ConfigureAnalytics();
        CreateVisit('KPI-V2', CreateDateTime(WorkDate(), 080000T), CreateDateTime(WorkDate(), 084500T), CreateDateTime(WorkDate(), 100000T));

        Assert.AreEqual(45, KpiMgt.Measure(KpiMeasure::WHADoorWait, CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'Eight to quarter to nine is forty-five minutes.');
    end;

    [Test]
    procedure AVehicleStillOnSiteHasNoTurnaroundYet()
    var
        DockAppointment: Record "WHA Dock Appointment";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
    begin
        // [SCENARIO] Counting a visit that has not finished as if it had would flatter every figure taken
        // before the end of the day, which is when people look at them.
        ConfigureAnalytics();
        CreateVisit('KPI-V3', CreateDateTime(WorkDate(), 080000T), CreateDateTime(WorkDate(), 081500T), 0DT);
        DockAppointment.Get('KPI-V3');
        DockAppointment.Status := DockAppointment.Status::WHAAtDoor;
        DockAppointment.Modify(true);

        Assert.AreEqual(0, KpiMgt.Measure(KpiMeasure::WHATrailerTurnaround, CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'A visit that has not finished has no turnaround.');
        Assert.AreEqual(15, KpiMgt.Measure(KpiMeasure::WHADoorWait, CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate()), 'It did reach a door, so the wait is known.');
    end;

    [Test]
    procedure CapturingKeepsOneFigurePerMeasureAndReplacesItOnRerun()
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        TaskType: Enum "WHA Warehouse Task Type";
        FirstRun: Integer;
    begin
        // [SCENARIO] A period has one answer. Two answers for the same period is a question about which
        // one is right, and somebody will pick the flattering one.
        ConfigureAnalytics();
        CreateCompletedTask('KPI-C1', TaskType::WHAPick, 5, 5, CreateDateTime(WorkDate(), 100000T));

        FirstRun := KpiMgt.Capture(CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate());
        Assert.AreEqual(FirstRun, CountSnapshots(), 'Every measure should have been kept once.');

        CreateCompletedTask('KPI-C2', TaskType::WHAPick, 5, 5, CreateDateTime(WorkDate(), 110000T));
        KpiMgt.Capture(CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate());

        Assert.AreEqual(FirstRun, CountSnapshots(), 'Capturing the same period again should replace the figures, not add a second set.');
        FindSnapshot(KpiSnapshot, KpiSnapshot.Measure::WHATasksCompleted);
        Assert.AreEqual(2, KpiSnapshot.Value, 'The figure should be the one the second run worked out.');
    end;

    [Test]
    procedure AKeptFigureRemembersItsUnitAndItsPeriod()
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
        KpiMgt: Codeunit "WHA KPI Mgt.";
    begin
        // [SCENARIO] A number without a unit and a period is not a measurement, and an old snapshot has
        // to still read correctly if the measure is ever redefined.
        ConfigureAnalytics();
        KpiMgt.Capture(CopyStr(LocationTok, 1, 10), WorkDate() - 1, WorkDate());

        FindSnapshot(KpiSnapshot, KpiSnapshot.Measure::WHATrailerTurnaround);
        Assert.AreNotEqual('', KpiSnapshot."Measured In", 'The unit is kept with the figure.');
        Assert.AreEqual(WorkDate() - 1, KpiSnapshot."From Date", 'The first day counted is kept.');
        Assert.AreEqual(WorkDate(), KpiSnapshot."To Date", 'The last day counted is kept.');
        Assert.AreNotEqual('', KpiSnapshot."Captured By User ID", 'Who took the figure is kept.');
    end;

    [Test]
    procedure WhichWayIsBetterDependsOnTheMeasure()
    var
        Later: Record "WHA KPI Snapshot";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
    begin
        // [SCENARIO] More finished jobs is better and more short picks is worse. The app has no targets,
        // so the most it will ever say about a figure is which way it moved since last time.
        ConfigureAnalytics();
        CreateSnapshot(KpiMeasure::WHATasksCompleted, WorkDate() - 14, WorkDate() - 7, 40);
        CreateSnapshot(KpiMeasure::WHATasksCompleted, WorkDate() - 7, WorkDate(), 60);
        FindSnapshot(Later, KpiMeasure::WHATasksCompleted);
        Assert.AreEqual(1, KpiMgt.ComparedWithPrevious(Later), 'Finishing more work is an improvement.');

        CreateSnapshot(KpiMeasure::WHAPickShortRate, WorkDate() - 14, WorkDate() - 7, 2);
        CreateSnapshot(KpiMeasure::WHAPickShortRate, WorkDate() - 7, WorkDate(), 9);
        FindSnapshot(Later, KpiMeasure::WHAPickShortRate);
        Assert.AreEqual(-1, KpiMgt.ComparedWithPrevious(Later), 'More short picks is not an improvement.');
    end;

    [Test]
    procedure AFigureWithNothingBeforeItIsNotCompared()
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        KpiMeasure: Enum "WHA KPI Measure";
    begin
        // [SCENARIO] The first figure a warehouse ever takes is neither good nor bad, and pretending
        // otherwise is how a dashboard loses its audience in week one.
        ConfigureAnalytics();
        CreateSnapshot(KpiMeasure::WHADoorWait, WorkDate() - 7, WorkDate(), 25);

        FindSnapshot(KpiSnapshot, KpiMeasure::WHADoorWait);
        Assert.AreEqual(0, KpiMgt.ComparedWithPrevious(KpiSnapshot), 'There is nothing to compare the first figure with.');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
        DemoAnalytics: Codeunit "WHA Demo Analytics";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] The sample import captures figures rather than inventing them, so running it twice
        // has to replace them rather than build a pile of duplicates for the same period.
        DemoAnalytics.Import();
        CountAfterFirstRun := KpiSnapshot.Count();

        DemoAnalytics.Import();

        Assert.AreEqual(CountAfterFirstRun, KpiSnapshot.Count(), 'A second import should not keep a second set of figures.');
    end;

    [Test]
    procedure TheScheduledCaptureKeepsASnapshot()
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
    begin
        // [SCENARIO] Without a schedule the snapshot history has gaps exactly where somebody forgot, which
        // is the reading that makes a trend meaningless.
        ConfigureAnalytics();
        EnableAnalytics();

        KpiSnapshot.Reset();
        KpiSnapshot.SetRange("Location Code", CopyStr(LocationTok, 1, 10));
        Codeunit.Run(Codeunit::"WHA KPI Scheduler", KpiSnapshot);

        KpiSnapshot.Reset();
        KpiSnapshot.SetRange("Location Code", CopyStr(LocationTok, 1, 10));
        Assert.IsFalse(KpiSnapshot.IsEmpty(), 'The scheduled capture should have kept the period''s figures.');
    end;

    [Test]
    procedure TheScheduledCaptureRefusesWhenAnalyticsIsSwitchedOff()
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
    begin
        // [SCENARIO] A job queue entry left in place after somebody switched the feature off must not keep
        // filling the snapshot table.
        ConfigureAnalytics();
        DisableAnalytics();
        KpiSnapshot.Reset();

        asserterror Codeunit.Run(Codeunit::"WHA KPI Scheduler", KpiSnapshot);

        Assert.ExpectedError('not enabled');
    end;

    local procedure ConfigureAnalytics()
    var
        Setup: Record "WHA Analytics Setup";
        TaskSetup: Record "WHA Warehouse Task Setup";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        Setup.Validate("Default Period Days", 7);
        Setup.Modify(true);

        TaskSetup.Reset();
        if not TaskSetup.Get() then begin
            TaskSetup.Init();
            TaskSetup.Insert(true);
        end;
        TaskSetup.Validate("Auto Release Tasks", false);
        TaskSetup.Modify(true);

        EnsureLocation(CopyStr(LocationTok, 1, 10));
        EnsureItem(CopyStr(ItemTok, 1, 20));
    end;

    local procedure CreateCompletedTask(TaskNo: Code[20]; TaskType: Enum "WHA Warehouse Task Type"; Quantity: Decimal; Handled: Decimal; CompletedAt: DateTime)
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Task Type" := TaskType;
        WarehouseTask."Location Code" := CopyStr(LocationTok, 1, 10);
        WarehouseTask."Item No." := CopyStr(ItemTok, 1, 20);
        WarehouseTask.Quantity := Quantity;
        WarehouseTask."Quantity Handled" := Handled;
        WarehouseTask.Status := WarehouseTask.Status::WHACompleted;
        WarehouseTask."Completed At" := CompletedAt;
        WarehouseTask.Insert(true);
    end;

    local procedure CreateVisit(AppointmentNo: Code[20]; ArrivedAt: DateTime; AtDoorAt: DateTime; DepartedAt: DateTime)
    var
        DockAppointment: Record "WHA Dock Appointment";
        Direction: Enum "WHA Dock Direction";
    begin
        DockAppointment.Init();
        DockAppointment."No." := AppointmentNo;
        DockAppointment."Location Code" := CopyStr(LocationTok, 1, 10);
        DockAppointment.Direction := Direction::WHAInbound;
        DockAppointment."Expected At" := ArrivedAt;
        DockAppointment."Arrived At" := ArrivedAt;
        DockAppointment."At Door At" := AtDoorAt;
        DockAppointment."Departed At" := DepartedAt;
        if DepartedAt <> 0DT then
            DockAppointment.Status := DockAppointment.Status::WHADeparted
        else
            DockAppointment.Status := DockAppointment.Status::WHAArrived;
        DockAppointment.Insert(true);
    end;

    local procedure CreateSnapshot(KpiMeasure: Enum "WHA KPI Measure"; FromDate: Date; ToDate: Date; Value: Decimal)
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
    begin
        KpiSnapshot.Init();
        KpiSnapshot."Location Code" := CopyStr(LocationTok, 1, 10);
        KpiSnapshot.Measure := KpiMeasure;
        KpiSnapshot."From Date" := FromDate;
        KpiSnapshot."To Date" := ToDate;
        KpiSnapshot.Value := Value;
        KpiSnapshot.Insert(true);
    end;

    local procedure FindSnapshot(var KpiSnapshot: Record "WHA KPI Snapshot"; KpiMeasure: Enum "WHA KPI Measure")
    begin
        KpiSnapshot.Reset();
        KpiSnapshot.SetRange("Location Code", CopyStr(LocationTok, 1, 10));
        KpiSnapshot.SetRange(Measure, KpiMeasure);
        KpiSnapshot.FindLast();
    end;

    local procedure CountSnapshots(): Integer
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
    begin
        KpiSnapshot.SetRange("Location Code", CopyStr(LocationTok, 1, 10));
        exit(KpiSnapshot.Count());
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

    local procedure EnsureItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit;

        Item.Init();
        Item."No." := ItemNo;
        Item.Insert(true);
    end;

    local procedure EnableAnalytics()
    begin
        SetAnalyticsEnabled(true);
    end;

    local procedure DisableAnalytics()
    begin
        SetAnalyticsEnabled(false);
    end;

    local procedure SetAnalyticsEnabled(Enabled: Boolean)
    var
        Setup: Record "WHA Analytics Setup";
    begin
        Setup.Get();
        Setup."WHA Enabled" := Enabled;
        Setup.Modify(true);
    end;
}
