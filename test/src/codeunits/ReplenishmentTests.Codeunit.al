codeunit 51007 "WHA Replenishment Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHAREPL', Locked = true;
        OtherLocationTok: Label 'WHAREPL2', Locked = true;
        PickBinTok: Label 'PICK-01', Locked = true;
        BulkBinTok: Label 'BULK-01', Locked = true;
        ItemTok: Label 'WHA-REPL-IT', Locked = true;
        NoSeriesTok: Label 'WHA-RTEST', Locked = true;

    [Test]
    procedure ABinBelowItsMinimumAsksForEnoughToFillIt()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        WarehouseTask: Record "WHA Warehouse Task";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] Replenishment is min/max, not min/min: a bin that has run low is filled back to the
        // top, or the same person is sent back to it an hour later.
        ConfigureReplenishment(true);
        StockInBin('WHA-REPL-U1', CopyStr(PickBinTok, 1, 20), 2);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);

        Assert.AreEqual(1, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'The run should have raised one piece of work.');

        FindWorkForBin(WarehouseTask, CopyStr(PickBinTok, 1, 20));
        Assert.AreEqual(48, WarehouseTask.Quantity, 'The work should ask for enough to fill the bin to its maximum.');
        Assert.AreEqual(WarehouseTask."Task Type"::WHAReplenishment, WarehouseTask."Task Type", 'The work should be replenishment work.');
        Assert.AreEqual(CopyStr(PickBinTok, 1, 20), WarehouseTask."To Bin Code", 'The work should deliver to the bin the rule looks after.');
        Assert.AreEqual(CopyStr(BulkBinTok, 1, 20), WarehouseTask."From Bin Code", 'The work should fetch from the source bin on the rule.');
    end;

    [Test]
    procedure ABinWithEnoughInItAsksForNothing()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] A rule that asks for work it does not need is a rule nobody leaves switched on.
        ConfigureReplenishment(true);
        StockInBin('WHA-REPL-U2', CopyStr(PickBinTok, 1, 20), 12);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);

        Assert.AreEqual(0, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'A bin above its minimum should not ask for anything.');
        Assert.AreEqual(0, ReplenishmentMgt.Shortfall(ReplenishmentRule), 'The shortfall should be nothing.');
    end;

    [Test]
    procedure TheSameBinIsNotAskedForTwice()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] Replenishment is meant to run on a schedule. Without this, a run every ten minutes
        // sends ten people to the same bin.
        ConfigureReplenishment(true);
        StockInBin('WHA-REPL-U3', CopyStr(PickBinTok, 1, 20), 1);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);

        Assert.AreEqual(1, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'The first run should raise work.');
        Assert.AreEqual(0, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'A second run should leave the bin alone.');
        Assert.AreEqual(1, WorkCountForBin(CopyStr(PickBinTok, 1, 20)), 'Only one piece of work should exist for the bin.');
    end;

    [Test]
    procedure WithdrawnWorkLetsTheBinAskAgain()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        WarehouseTask: Record "WHA Warehouse Task";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        // [SCENARIO] The guard is about outstanding work, not about work that ever existed. A cancelled
        // job must not leave the bin unable to ask for help.
        ConfigureReplenishment(true);
        StockInBin('WHA-REPL-U4', CopyStr(PickBinTok, 1, 20), 1);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);
        ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10));

        FindWorkForBin(WarehouseTask, CopyStr(PickBinTok, 1, 20));
        TaskLogic.Cancel(WarehouseTask);

        Assert.AreEqual(1, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'The bin should be able to ask again once the work is withdrawn.');
        Assert.AreEqual(2, WorkCountForBin(CopyStr(PickBinTok, 1, 20)), 'Both pieces of work should be on record.');
    end;

    [Test]
    procedure ABlockedRuleIsLeftAlone()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] Blocking a rule is how a warehouse switches one off without losing what it says, so a
        // run must not act on it and asking it directly must say why.
        ConfigureReplenishment(true);
        StockInBin('WHA-REPL-U5', CopyStr(PickBinTok, 1, 20), 0);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);
        ReplenishmentRule.Validate(Blocked, true);
        ReplenishmentRule.Modify(true);

        Assert.AreEqual(0, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'A run should skip a blocked rule.');

        asserterror ReplenishmentMgt.RunRule(ReplenishmentRule);
        Assert.ExpectedError('is blocked');
    end;

    [Test]
    procedure ARunOnlyLooksAtTheLocationItWasGiven()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] Replenishment is run per site and per shift. A run at one location must not raise
        // work at the other end of the country.
        ConfigureReplenishment(true);
        CreateRule(ReplenishmentRule, CopyStr(OtherLocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);

        Assert.AreEqual(0, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'A run should not touch rules at another location.');
        Assert.AreEqual(0, WorkCountForBin(CopyStr(PickBinTok, 1, 20)), 'No work should have been raised.');
    end;

    [Test]
    procedure StockOnAUnitInAnotherBinIsNotCounted()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] The whole point of a pick face is where the goods are standing. Stock in the bulk bin
        // is exactly what replenishment exists to move, so counting it would make the rule never fire.
        ConfigureReplenishment(true);
        StockInBin('WHA-REPL-U6', CopyStr(BulkBinTok, 1, 20), 500);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);

        Assert.AreEqual(0, ReplenishmentMgt.Measure(ReplenishmentRule), 'Only what stands in the bin itself should be measured.');
        Assert.AreEqual(50, ReplenishmentMgt.Shortfall(ReplenishmentRule), 'An empty pick face should ask to be filled to its maximum.');
    end;

    [Test]
    procedure AMinimumAboveTheMaximumIsRefused()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
    begin
        // [SCENARIO] A rule that says fill to 5 when it drops below 10 would ask for work every time it
        // was run and never be satisfied.
        ConfigureReplenishment(true);
        ReplenishmentRule.Init();
        ReplenishmentRule."Location Code" := CopyStr(LocationTok, 1, 10);
        ReplenishmentRule."Item No." := CopyStr(ItemTok, 1, 20);
        ReplenishmentRule."Bin Code" := CopyStr(PickBinTok, 1, 20);
        ReplenishmentRule.Validate("Maximum Quantity", 5);

        asserterror ReplenishmentRule.Validate("Minimum Quantity", 10);

        Assert.ExpectedError('more than the maximum');
    end;

    [Test]
    procedure RaisedWorkGoesToTheFloorWhenTheSetupSaysSo()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        WarehouseTask: Record "WHA Warehouse Task";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] Replenishment that has to be released by hand is replenishment nobody runs on a
        // schedule.
        ConfigureReplenishment(true);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);

        ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10));

        FindWorkForBin(WarehouseTask, CopyStr(PickBinTok, 1, 20));
        Assert.AreEqual(WarehouseTask.Status::WHAReleased, WarehouseTask.Status, 'The work should be on the floor.');
    end;

    [Test]
    procedure RaisedWorkStaysADraftWhenTheSetupAsksForThat()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        WarehouseTask: Record "WHA Warehouse Task";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] A warehouse that wants to look at what a run proposed before anybody is sent to do it
        // can have that, and the setting is the only difference.
        ConfigureReplenishment(false);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);

        ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10));

        FindWorkForBin(WarehouseTask, CopyStr(PickBinTok, 1, 20));
        Assert.AreEqual(WarehouseTask.Status::WHACreated, WarehouseTask.Status, 'The work should have been left as a draft.');
    end;

    [Test]
    procedure ARunStampsWhenItLookedAtTheRule()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] A rule that never asks for anything and a rule nobody has run look identical without
        // this, and the second one is a fault.
        ConfigureReplenishment(true);
        StockInBin('WHA-REPL-U7', CopyStr(PickBinTok, 1, 20), 99);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 10, 50);

        ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10));

        ReplenishmentRule.Get(CopyStr(LocationTok, 1, 10), CopyStr(ItemTok, 1, 20), '', CopyStr(PickBinTok, 1, 20));
        Assert.IsTrue(ReplenishmentRule."Last Checked At" <> 0DT, 'The run should record that it looked.');
        Assert.AreEqual('', ReplenishmentRule."Last Task No.", 'Nothing was raised, so no work should be recorded.');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        DemoReplenishment: Codeunit "WHA Demo Replenishment";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice creates the rules once.
        DemoReplenishment.Import();
        CountAfterFirstRun := ReplenishmentRule.Count();

        DemoReplenishment.Import();

        Assert.AreEqual(CountAfterFirstRun, ReplenishmentRule.Count(), 'A second import should not create more rules.');
    end;

    [Test]
    procedure ABinThatIsFullNowButPromisedAwayIsSeenAsLow()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        WarehouseTask: Record "WHA Warehouse Task";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] The whole point of looking ahead. A pick face with a hundred pieces in it and ninety
        // already promised has ten, and a run that only reads the shelf sends nobody.
        ConfigureReplenishment(false);
        ConfigureDemand();
        StockInBin('WHA-RP-D1', CopyStr(PickBinTok, 1, 20), 100);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 20, 100);
        RaisePick('WHA-RP-P1', 90, '');

        Assert.AreEqual(1, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'The bin is promised away, so it needs filling.');

        FindWorkForBin(WarehouseTask, CopyStr(PickBinTok, 1, 20));
        Assert.AreEqual(90, WarehouseTask.Quantity, 'It should ask for what is missing once the promise is taken off.');
    end;

    [Test]
    procedure LookingOnlyAtTheShelfMissesTheSameBin()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] The behaviour before this segment, kept as a configured choice. It is also what a
        // fresh installation does, so nobody's runs change under them on upgrade.
        ConfigureReplenishment(false);
        ConfigureNoDemand();
        StockInBin('WHA-RP-D2', CopyStr(PickBinTok, 1, 20), 100);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 20, 100);
        RaisePick('WHA-RP-P2', 90, '');

        Assert.AreEqual(0, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'The shelf is full, so this way of looking sees nothing to do.');
    end;

    [Test]
    procedure WorkAlreadyWalkedIsNoLongerAPromise()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] A pick that has been part-filled has only its remainder still to take. Counting the
        // whole job again would fill the bin twice.
        ConfigureReplenishment(false);
        ConfigureDemand();
        StockInBin('WHA-RP-D3', CopyStr(PickBinTok, 1, 20), 100);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 20, 100);
        RaisePartlyWalkedPick('WHA-RP-P3', 90, 85);

        Assert.AreEqual(0, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'Only five of the ninety are still to come, so the bin is fine.');
    end;

    [Test]
    procedure PreReplenishingAWaveLooksOnlyAtThatWave()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        Wave: Record "WHA Wave";
        WarehouseTask: Record "WHA Warehouse Task";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] Filling a pick face for the wave that is about to go out is a different question from
        // filling it for everything ever planned, and answering the wrong one over-fills the bin.
        ConfigureReplenishment(false);
        ConfigureNoDemand();
        StockInBin('WHA-RP-D4', CopyStr(PickBinTok, 1, 20), 100);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 20, 100);
        CreateWave(Wave, 'WHA-RP-W1');
        RaisePick('WHA-RP-P4', 90, Wave."No.");
        RaisePick('WHA-RP-P5', 50, '');

        Assert.AreEqual(1, ReplenishmentMgt.RunForWave(Wave), 'The wave promises ninety of the hundred, so the bin needs filling.');

        FindWorkForBin(WarehouseTask, CopyStr(PickBinTok, 1, 20));
        Assert.AreEqual(90, WarehouseTask.Quantity, 'Only the wave''s ninety counts, not the fifty outside it.');
    end;

    [Test]
    procedure PreReplenishingNamesTheWaveOnTheWorkItRaises()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        Wave: Record "WHA Wave";
        WarehouseTask: Record "WHA Warehouse Task";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] An operator handed a replenishment job should be able to see it exists because a
        // particular wave is waiting on it.
        ConfigureReplenishment(false);
        ConfigureNoDemand();
        StockInBin('WHA-RP-D5', CopyStr(PickBinTok, 1, 20), 100);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 20, 100);
        CreateWave(Wave, 'WHA-RP-W2');
        RaisePick('WHA-RP-P6', 95, Wave."No.");

        ReplenishmentMgt.RunForWave(Wave);

        FindWorkForBin(WarehouseTask, CopyStr(PickBinTok, 1, 20));
        Assert.IsTrue(WarehouseTask.Description.Contains(Wave."No."), 'The job should say which wave it is being prepared for.');
    end;

    [Test]
    procedure AWaveThatIsFinishedCannotBePreReplenished()
    var
        Wave: Record "WHA Wave";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
        WaveLogic: Codeunit "WHA Wave Logic";
    begin
        // [SCENARIO] Pre-replenishment fills a pick face before the work goes out. Asking for it after the
        // wave is over is a mistake worth being told about rather than a run that quietly does nothing.
        ConfigureReplenishment(false);
        ConfigureNoDemand();
        CreateWave(Wave, 'WHA-RP-W3');
        WaveLogic.Cancel(Wave);

        asserterror ReplenishmentMgt.RunForWave(Wave);

        Assert.ExpectedError('nothing left to prepare for');
    end;

    [Test]
    procedure APickThatNamesAnotherBinIsNotAPromiseAgainstThisOne()
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        // [SCENARIO] A pick that says where it is coming from, and says somewhere else, is nothing to do
        // with this pick face.
        ConfigureReplenishment(false);
        ConfigureDemand();
        StockInBin('WHA-RP-D6', CopyStr(PickBinTok, 1, 20), 100);
        CreateRule(ReplenishmentRule, CopyStr(LocationTok, 1, 10), CopyStr(PickBinTok, 1, 20), 20, 100);
        RaisePickFromBin('WHA-RP-P7', 90, CopyStr(BulkBinTok, 1, 20));

        Assert.AreEqual(0, ReplenishmentMgt.Run(CopyStr(LocationTok, 1, 10)), 'That pick is drawing from the bulk bin, not this pick face.');
    end;

    local procedure ConfigureReplenishment(ReleaseWork: Boolean)
    var
        Setup: Record "WHA Repl. Setup";
        TaskSetup: Record "WHA Warehouse Task Setup";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        Setup.Validate("Default Priority", 20);
        Setup.Validate("Release Replenishment Work", ReleaseWork);
        Setup.Modify(true);

        TaskSetup.Reset();
        if not TaskSetup.Get() then begin
            TaskSetup.Init();
            TaskSetup.Insert(true);
        end;
        TaskSetup.Validate("Auto Release Tasks", false);
        TaskSetup.Modify(true);

        EnsureLocation(CopyStr(LocationTok, 1, 10));
        EnsureLocation(CopyStr(OtherLocationTok, 1, 10));
        EnsureItem();
        EnsureTaskNoSeries();
    end;

    local procedure CreateRule(var ReplenishmentRule: Record "WHA Replenishment Rule"; LocationCode: Code[10]; BinCode: Code[20]; Minimum: Decimal; Maximum: Decimal)
    var
        Method: Enum "WHA Repl. Method";
    begin
        ReplenishmentRule.Init();
        ReplenishmentRule."Location Code" := LocationCode;
        ReplenishmentRule."Item No." := CopyStr(ItemTok, 1, 20);
        ReplenishmentRule."Bin Code" := BinCode;
        ReplenishmentRule."Source Bin Code" := CopyStr(BulkBinTok, 1, 20);
        ReplenishmentRule.Validate(Method, Method::WHAHandlingUnits);
        ReplenishmentRule.Validate("Maximum Quantity", Maximum);
        ReplenishmentRule.Validate("Minimum Quantity", Minimum);
        ReplenishmentRule.Insert(true);
    end;

    local procedure StockInBin(UnitNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit."Location Code" := CopyStr(LocationTok, 1, 10);
        HandlingUnit."Bin Code" := BinCode;
        HandlingUnit.Insert(true);

        if Quantity = 0 then
            exit;

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Item No." := CopyStr(ItemTok, 1, 20);
        HandlingUnitLine.Quantity := Quantity;
        HandlingUnitLine.Insert(true);
    end;

    local procedure FindWorkForBin(var WarehouseTask: Record "WHA Warehouse Task"; BinCode: Code[20])
    begin
        WarehouseTask.SetRange("Task Type", WarehouseTask."Task Type"::WHAReplenishment);
        WarehouseTask.SetRange("To Bin Code", BinCode);
        WarehouseTask.SetFilter(Status, '<>%1', WarehouseTask.Status::WHACancelled);
        WarehouseTask.FindFirst();
    end;

    local procedure WorkCountForBin(BinCode: Code[20]): Integer
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetRange("Task Type", WarehouseTask."Task Type"::WHAReplenishment);
        WarehouseTask.SetRange("To Bin Code", BinCode);
        exit(WarehouseTask.Count());
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

    local procedure EnsureItem()
    var
        Item: Record Item;
    begin
        if Item.Get(CopyStr(ItemTok, 1, 20)) then
            exit;

        Item.Init();
        Item."No." := CopyStr(ItemTok, 1, 20);
        Item.Insert(true);
    end;

    local procedure EnsureTaskNoSeries()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        TaskSetup: Record "WHA Warehouse Task Setup";
    begin
        if not NoSeries.Get(CopyStr(NoSeriesTok, 1, 20)) then begin
            NoSeries.Init();
            NoSeries.Code := CopyStr(NoSeriesTok, 1, 20);
            NoSeries."Default Nos." := true;
            NoSeries.Insert(true);

            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeries.Code;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'RT000001';
            NoSeriesLine."Ending No." := 'RT999999';
            NoSeriesLine.Insert(true);
        end;

        TaskSetup.Reset();
        if not TaskSetup.Get() then begin
            TaskSetup.Init();
            TaskSetup.Insert(true);
        end;
        if TaskSetup."Warehouse Task Nos." <> '' then
            exit;

        TaskSetup.Validate("Warehouse Task Nos.", CopyStr(NoSeriesTok, 1, 20));
        TaskSetup.Modify(true);
    end;

    local procedure ConfigureDemand()
    var
        Setup: Record "WHA Repl. Setup";
        Demand: Enum "WHA Repl. Demand";
    begin
        Setup.Get();
        Setup.Validate("Demand Method", Demand::WHAOutstandingPicks);
        Setup.Modify(true);
    end;

    local procedure ConfigureNoDemand()
    var
        Setup: Record "WHA Repl. Setup";
        Demand: Enum "WHA Repl. Demand";
    begin
        Setup.Get();
        Setup.Validate("Demand Method", Demand::WHANone);
        Setup.Modify(true);
    end;

    local procedure RaisePick(TaskNo: Code[20]; Quantity: Decimal; WaveNo: Code[20])
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        InitPick(WarehouseTask, TaskNo, Quantity);
        WarehouseTask."Wave No." := WaveNo;
        WarehouseTask.Insert(true);
    end;

    local procedure RaisePickFromBin(TaskNo: Code[20]; Quantity: Decimal; FromBinCode: Code[20])
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        InitPick(WarehouseTask, TaskNo, Quantity);
        WarehouseTask."From Bin Code" := FromBinCode;
        WarehouseTask.Insert(true);
    end;

    local procedure RaisePartlyWalkedPick(TaskNo: Code[20]; Quantity: Decimal; Handled: Decimal)
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        InitPick(WarehouseTask, TaskNo, Quantity);
        WarehouseTask."Quantity Handled" := Handled;
        WarehouseTask.Insert(true);
    end;

    local procedure InitPick(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20]; Quantity: Decimal)
    begin
        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Task Type" := WarehouseTask."Task Type"::WHAPick;
        WarehouseTask."Location Code" := CopyStr(LocationTok, 1, 10);
        WarehouseTask."Item No." := CopyStr(ItemTok, 1, 20);
        WarehouseTask.Quantity := Quantity;
    end;

    local procedure CreateWave(var Wave: Record "WHA Wave"; WaveNo: Code[20])
    begin
        Wave.Init();
        Wave."No." := WaveNo;
        Wave."Location Code" := CopyStr(LocationTok, 1, 10);
        Wave.Insert(true);
    end;
}
