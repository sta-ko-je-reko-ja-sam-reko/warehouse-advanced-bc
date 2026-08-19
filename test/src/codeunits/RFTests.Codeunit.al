codeunit 51003 "WHA RF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHARF', Locked = true;
        OtherLocationTok: Label 'WHARF2', Locked = true;
        FromBinTok: Label 'RF-FROM-01', Locked = true;
        ToBinTok: Label 'RF-TO-01', Locked = true;
        DeviceTok: Label 'RF-DEV-01', Locked = true;

    [Test]
    procedure SignInRefusesAnUnknownDevice()
    var
        RFDevice: Record "WHA RF Device";
        Flow: Codeunit "WHA RF Standard Flow";
    begin
        // [SCENARIO] With registration required, a handheld nobody has registered cannot be used — that
        // is the point of registering them.
        ConfigureHandheld(true, true);

        asserterror Flow.SignIn('RF-NOBODY', RFDevice);

        Assert.ExpectedError('is not registered');
    end;

    [Test]
    procedure SignInRefusesABlockedDevice()
    var
        RFDevice: Record "WHA RF Device";
        Flow: Codeunit "WHA RF Standard Flow";
    begin
        // [SCENARIO] A handheld taken out of use stays out of use, registered or not.
        ConfigureHandheld(true, true);
        CreateDevice('RF-BLOCKED', '', true);

        asserterror Flow.SignIn('RF-BLOCKED', RFDevice);

        Assert.ExpectedError('is blocked');
    end;

    [Test]
    procedure SignInStampsTheDevice()
    var
        RFDevice: Record "WHA RF Device";
        Flow: Codeunit "WHA RF Standard Flow";
    begin
        // [SCENARIO] Signing in records who has the handheld and when, which is how a device left in a
        // rack is found.
        ConfigureHandheld(true, true);
        EnsureLocation(LocationTok);
        CreateDevice(CopyStr(DeviceTok, 1, 20), CopyStr(LocationTok, 1, 10), false);

        Flow.SignIn(CopyStr(DeviceTok, 1, 20), RFDevice);

        Assert.AreEqual(LocationTok, RFDevice."Default Location Code", 'Signing in should bring back the location the handheld works at.');
        Assert.IsTrue(RFDevice."Last Seen At" <> 0DT, 'Signing in should record when the handheld was last used.');
        Assert.AreNotEqual('', RFDevice."Last User ID", 'Signing in should record who used the handheld.');
    end;

    [Test]
    procedure AnUnregisteredDeviceIsAllowedWhenRegistrationIsOff()
    var
        RFDevice: Record "WHA RF Device";
        Flow: Codeunit "WHA RF Standard Flow";
    begin
        // [SCENARIO] Trying the screen out from a desktop must not require someone to register the
        // desktop first.
        ConfigureHandheld(true, false);

        Flow.SignIn('', RFDevice);

        Assert.AreEqual('', RFDevice."Code", 'Signing in without a device should be allowed and bring back no device.');
    end;

    [Test]
    procedure TheFirstStepIsTheBinToTakeFrom()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] A job that names a bin to take from starts by sending the operator to that bin.
        ConfigureHandheld(true, false);
        WarehouseTask."From Bin Code" := CopyStr(FromBinTok, 1, 20);
        WarehouseTask."To Bin Code" := CopyStr(ToBinTok, 1, 20);

        Assert.AreEqual(Step::WHAScanFrom, Flow.FirstStep(WarehouseTask), 'A job with a from bin should start there.');
    end;

    [Test]
    procedure AJobWithNoBinsGoesStraightToConfirm()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] There is nothing to scan on a job that names no bins and no unit, so the operator
        // is asked to confirm and nothing else.
        ConfigureHandheld(true, false);

        Assert.AreEqual(Step::WHAConfirm, Flow.FirstStep(WarehouseTask), 'A job with nothing to scan should go straight to confirm.');
    end;

    [Test]
    procedure ScanningCanBeSwitchedOffEntirely()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] With confirm-by-scan off, even a job full of bins is one tap. Quicker, and it proves
        // nothing about where the operator was standing.
        ConfigureHandheld(false, false);
        WarehouseTask."From Bin Code" := CopyStr(FromBinTok, 1, 20);
        WarehouseTask."To Bin Code" := CopyStr(ToBinTok, 1, 20);

        Assert.AreEqual(Step::WHAConfirm, Flow.FirstStep(WarehouseTask), 'With scanning off the job should go straight to confirm.');
    end;

    [Test]
    procedure ScanningTheWrongBinIsRefused()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] Standing in the wrong aisle is exactly what the scan is there to catch, and the
        // operator is told where to go instead.
        ConfigureHandheld(true, false);
        WarehouseTask."From Bin Code" := CopyStr(FromBinTok, 1, 20);

        asserterror Flow.Scan(WarehouseTask, Step::WHAScanFrom, 'SOMEWHERE-ELSE');

        Assert.ExpectedError(FromBinTok);
    end;

    [Test]
    procedure ScanningTheRightBinMovesOn()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] The steps follow what the job actually names: from bin, then the unit, then the
        // destination.
        ConfigureHandheld(true, false);
        WarehouseTask."From Bin Code" := CopyStr(FromBinTok, 1, 20);
        WarehouseTask."To Bin Code" := CopyStr(ToBinTok, 1, 20);

        Assert.AreEqual(Step::WHAScanTo, Flow.Scan(WarehouseTask, Step::WHAScanFrom, FromBinTok), 'Scanning the from bin should move on to the destination.');
        Assert.AreEqual(Step::WHAConfirm, Flow.Scan(WarehouseTask, Step::WHAScanTo, ToBinTok), 'Scanning the destination should ask for confirmation.');
    end;

    [Test]
    procedure ScansAreNotCaseSensitiveOrSpaceSensitive()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] Scanners and people do not agree about case or trailing spaces, and neither should
        // cost an operator a walk.
        ConfigureHandheld(true, false);
        WarehouseTask."From Bin Code" := CopyStr(FromBinTok, 1, 20);

        Assert.AreEqual(Step::WHAConfirm, Flow.Scan(WarehouseTask, Step::WHAScanFrom, ' rf-from-01 '), 'A scan should be accepted whatever its case and spacing.');
    end;

    [Test]
    procedure TheHandlingUnitCanBeScannedByItsLabel()
    var
        HandlingUnit: Record "WHA Handling Unit";
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] The number the app assigned and the SSCC printed on the label identify the same
        // pallet. An operator scans whichever barcode is in front of them.
        ConfigureHandheld(true, false);

        HandlingUnit.Init();
        HandlingUnit."No." := 'RF-HU-001';
        HandlingUnit.SSCC := '380123456789099999';
        HandlingUnit.Insert(true);

        WarehouseTask."Handling Unit No." := HandlingUnit."No.";
        WarehouseTask."To Bin Code" := CopyStr(ToBinTok, 1, 20);

        Assert.AreEqual(Step::WHAScanTo, Flow.Scan(WarehouseTask, Step::WHAScanUnit, '380123456789099999'), 'Scanning the SSCC should be accepted as the unit.');
        Assert.AreEqual(Step::WHAScanTo, Flow.Scan(WarehouseTask, Step::WHAScanUnit, 'RF-HU-001'), 'Scanning the unit number should be accepted too.');
    end;

    [Test]
    procedure ScanningTheWrongUnitIsRefused()
    var
        HandlingUnit: Record "WHA Handling Unit";
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] Picking up the pallet next to the right one is the mistake this catches.
        ConfigureHandheld(true, false);

        HandlingUnit.Init();
        HandlingUnit."No." := 'RF-HU-002';
        HandlingUnit.Insert(true);

        WarehouseTask."Handling Unit No." := HandlingUnit."No.";

        asserterror Flow.Scan(WarehouseTask, Step::WHAScanUnit, 'RF-HU-999');

        Assert.ExpectedError('RF-HU-002');
    end;

    [Test]
    procedure TheInstructionNamesTheBin()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] The instruction is the whole user interface of a handheld, so it has to say where
        // to go, not merely what state the screen is in.
        ConfigureHandheld(true, false);
        WarehouseTask."From Bin Code" := CopyStr(FromBinTok, 1, 20);

        Assert.ExpectedMessage(FromBinTok, Flow.Instruction(WarehouseTask, Step::WHAScanFrom));
    end;

    [Test]
    procedure ConfirmingBeforeTheStepsAreDoneIsRefused()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
    begin
        // [SCENARIO] An operator cannot skip the scans by reaching for Confirm.
        ConfigureHandheld(true, false);
        WarehouseTask."No." := 'RF-TASK-EARLY';

        asserterror Flow.Confirm(WarehouseTask, Step::WHAScanFrom);

        Assert.ExpectedError('Finish the steps');
    end;

    [Test]
    procedure ConfirmingFinishesTheJob()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        Step: Enum "WHA RF Step";
        NextStep: Enum "WHA RF Step";
    begin
        // [SCENARIO] Confirming on the handheld completes the task, so the desk sees the work as done
        // without anybody typing anything. The operator never had to start it explicitly — picking the
        // job up is starting it.
        ConfigureHandheld(true, false);
        CreateAssignedTask(WarehouseTask, 'RF-TASK-DONE');

        NextStep := Flow.Confirm(WarehouseTask, Step::WHAConfirm);

        Assert.AreEqual(WarehouseTask.Status::WHACompleted, WarehouseTask.Status, 'Confirming should complete the task.');
        Assert.IsTrue(WarehouseTask."Started At" <> 0DT, 'Confirming should record that the work was started.');
        Assert.AreEqual(Step::WHAGetWork, NextStep, 'Finishing a job should leave the operator ready for the next one.');
    end;

    [Test]
    procedure HandingBackReturnsStartedWorkToTheQueue()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        Step: Enum "WHA RF Step";
        NextStep: Enum "WHA RF Step";
    begin
        // [SCENARIO] An operator who cannot finish a job puts it back. Work that was already started
        // must return to the queue for somebody else, not sit in progress with nobody holding it.
        ConfigureHandheld(true, false);
        CreateAssignedTask(WarehouseTask, 'RF-TASK-BACK');
        TaskLogic.Start(WarehouseTask);

        NextStep := Flow.HandBack(WarehouseTask);

        Assert.AreEqual(WarehouseTask.Status::WHAReleased, WarehouseTask.Status, 'Handing back started work should return it to the queue.');
        Assert.AreEqual('', WarehouseTask."Assigned To User ID", 'Handing back should leave nobody holding the job.');
        Assert.AreEqual(0DT, WarehouseTask."Started At", 'Handing back should clear when the work started, because it did not.');
        Assert.AreEqual(Step::WHAGetWork, NextStep, 'Handing back should leave the operator ready for the next job.');
    end;

    [Test]
    procedure WorkIsOfferedOnlyAtTheDeviceLocation()
    var
        RFDevice: Record "WHA RF Device";
        HereTask: Record "WHA Warehouse Task";
        ElsewhereTask: Record "WHA Warehouse Task";
        OfferedTask: Record "WHA Warehouse Task";
        Flow: Codeunit "WHA RF Standard Flow";
    begin
        // [SCENARIO] A handheld belongs to a part of the warehouse. An operator holding it is never sent
        // to the other end of the site, however urgent the work there is.
        ConfigureHandheld(true, true);
        EnsureLocation(LocationTok);
        EnsureLocation(OtherLocationTok);
        EnsureCurrentUser();

        CreateReleasedTask(ElsewhereTask, 'RF-ELSEWHERE', CopyStr(OtherLocationTok, 1, 10), 1);
        CreateReleasedTask(HereTask, 'RF-HERE', CopyStr(LocationTok, 1, 10), 90);

        CreateDevice(CopyStr(DeviceTok, 1, 20), CopyStr(LocationTok, 1, 10), false);
        Flow.SignIn(CopyStr(DeviceTok, 1, 20), RFDevice);

        Assert.IsTrue(Flow.NextTask(RFDevice, OfferedTask), 'There should be work at the handheld location.');

        Assert.AreEqual('RF-HERE', OfferedTask."No.", 'A handheld should only be offered work at its own location.');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        RFDevice: Record "WHA RF Device";
        DemoRFDevice: Codeunit "WHA Demo RF Device";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice creates the devices once.
        DemoRFDevice.Import();
        RFDevice.SetFilter("Code", 'DEMO-RF-*');
        CountAfterFirstRun := RFDevice.Count();

        DemoRFDevice.Import();

        Assert.AreEqual(3, CountAfterFirstRun, 'The first import should create three sample handhelds.');
        Assert.AreEqual(CountAfterFirstRun, RFDevice.Count(), 'A second import should not create more devices.');
    end;

    local procedure ConfigureHandheld(ConfirmByScan: Boolean; RequireDevice: Boolean)
    var
        Setup: Record "WHA RF Setup";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;

        Setup.Validate("Confirm By Scan", ConfirmByScan);
        Setup.Validate("Require Device Registration", RequireDevice);
        Setup.Validate("Auto Start Task", false);
        Setup.Modify(true);
    end;

    local procedure CreateDevice(DeviceCode: Code[20]; LocationCode: Code[10]; IsBlocked: Boolean)
    var
        RFDevice: Record "WHA RF Device";
    begin
        if RFDevice.Get(DeviceCode) then
            exit;

        RFDevice.Init();
        RFDevice."Code" := DeviceCode;
        RFDevice."Default Location Code" := LocationCode;
        RFDevice.Blocked := IsBlocked;
        RFDevice.Insert(true);
    end;

    local procedure CreateAssignedTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20])
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        EnsureLocation(LocationTok);
        EnsureCurrentUser();
        CreateReleasedTask(WarehouseTask, TaskNo, CopyStr(LocationTok, 1, 10), 50);
        TaskLogic.Assign(WarehouseTask, CopyStr(UserId(), 1, MaxStrLen(WarehouseTask."Assigned To User ID")));
    end;

    local procedure CreateReleasedTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20]; LocationCode: Code[10]; TaskPriority: Integer)
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Location Code" := LocationCode;
        WarehouseTask."Item No." := 'RF-ITEM';
        WarehouseTask.Quantity := 1;
        WarehouseTask.Priority := TaskPriority;
        WarehouseTask.Insert(true);

        if WarehouseTask.Status = WarehouseTask.Status::WHACreated then
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

    local procedure EnsureCurrentUser()
    var
        User: Record User;
        CurrentUserName: Code[50];
    begin
        CurrentUserName := CopyStr(UserId(), 1, MaxStrLen(CurrentUserName));
        User.SetRange("User Name", CurrentUserName);
        if not User.IsEmpty() then
            exit;

        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := CurrentUserName;
        User.Insert();
    end;
}
