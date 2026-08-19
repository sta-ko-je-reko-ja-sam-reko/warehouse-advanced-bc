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
        WarehouseSetup: Record "WHA Warehouse Setup";
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

        WarehouseSetup.Reset();
        if not WarehouseSetup.Get() then begin
            WarehouseSetup.Init();
            WarehouseSetup.Insert(true);
        end;
        if WarehouseSetup."Warehouse Task Nos." <> '' then
            exit;

        WarehouseSetup.Validate("Warehouse Task Nos.", CopyStr(NoSeriesTok, 1, 20));
        WarehouseSetup.Modify(true);
    end;
}
