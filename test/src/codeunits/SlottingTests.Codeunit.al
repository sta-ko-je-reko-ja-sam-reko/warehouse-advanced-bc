codeunit 51011 "WHA Slotting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHASLOT', Locked = true;
        GoodBinTok: Label 'GOLD-01', Locked = true;
        PoorBinTok: Label 'BACK-99', Locked = true;
        FastItemTok: Label 'WHA-SLOT-FAST', Locked = true;
        SlowItemTok: Label 'WHA-SLOT-SLOW', Locked = true;

    [Test]
    procedure VelocityIsMeasuredFromThePicksAlreadyDone()
    var
        ItemVelocity: Record "WHA Item Velocity";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] Nothing is entered to make this work. The warehouse has been recording every finished
        // pick since directed work shipped, and this is the first thing that reads it.
        ConfigureSlotting(1);
        CreatePick('SLOT-1', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 4);
        CreatePick('SLOT-2', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 6);
        CreatePick('SLOT-3', CopyStr(SlowItemTok, 1, 20), CopyStr(GoodBinTok, 1, 20), 1);

        Assert.AreEqual(2, SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D), 'Two items were picked, so two should be measured.');

        ItemVelocity.Get(CopyStr(LocationTok, 1, 10), CopyStr(FastItemTok, 1, 20), '');
        Assert.AreEqual(2, ItemVelocity.Movements, 'The fast item was picked twice.');
        Assert.AreEqual(10, ItemVelocity."Quantity Moved", 'Four and six is ten.');
        Assert.AreEqual(CopyStr(PoorBinTok, 1, 20), ItemVelocity."Main Bin Code", 'It should record where the item is picked from.');
    end;

    [Test]
    procedure TheFastestItemsAreClassA()
    var
        FastVelocity: Record "WHA Item Velocity";
        SlowVelocity: Record "WHA Item Velocity";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] The whole point of the classification: a small share of the items accounts for most of
        // the walking, and those are the ones that deserve the good bins.
        ConfigureSlotting(1);
        CreatePick('SLOT-A1', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-A2', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-A3', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-A4', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-B1', CopyStr(SlowItemTok, 1, 20), CopyStr(GoodBinTok, 1, 20), 1);

        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);

        FastVelocity.Get(CopyStr(LocationTok, 1, 10), CopyStr(FastItemTok, 1, 20), '');
        SlowVelocity.Get(CopyStr(LocationTok, 1, 10), CopyStr(SlowItemTok, 1, 20), '');
        Assert.AreEqual(FastVelocity.Class::WHAClassA, FastVelocity.Class, 'The item picked four times out of five should be class A.');
        Assert.AreNotEqual(SlowVelocity.Class::WHAClassA, SlowVelocity.Class, 'The item picked once should not be class A.');
    end;

    [Test]
    procedure AnItemPickedTooFewTimesIsNotClassified()
    var
        ItemVelocity: Record "WHA Item Velocity";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] An item picked once is not slow moving; it is unmeasured. Calling it class C would
        // send somebody to move stock on the strength of a single trip.
        ConfigureSlotting(3);
        CreatePick('SLOT-ONE', CopyStr(SlowItemTok, 1, 20), CopyStr(GoodBinTok, 1, 20), 1);

        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);

        ItemVelocity.Get(CopyStr(LocationTok, 1, 10), CopyStr(SlowItemTok, 1, 20), '');
        Assert.AreEqual(ItemVelocity.Class::WHAUnclassified, ItemVelocity.Class, 'Too few picks to say anything.');
    end;

    [Test]
    procedure TheQuantityBasisRanksDifferentlyFromTheMovementBasis()
    var
        Setup: Record "WHA Slotting Setup";
        FastVelocity: Record "WHA Item Velocity";
        SlowVelocity: Record "WHA Item Velocity";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
        Basis: Enum "WHA Velocity Basis";
    begin
        // [SCENARIO] One item is fetched often in ones; the other is fetched rarely by the pallet. Which
        // of them deserves the good bin depends entirely on what the warehouse counts as work.
        ConfigureSlotting(1);
        CreatePick('SLOT-Q1', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-Q2', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-Q3', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-Q4', CopyStr(SlowItemTok, 1, 20), CopyStr(GoodBinTok, 1, 20), 500);

        Setup.Get();
        Setup.Validate(Basis, Basis::WHAByQuantity);
        Setup.Modify(true);

        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);

        FastVelocity.Get(CopyStr(LocationTok, 1, 10), CopyStr(FastItemTok, 1, 20), '');
        SlowVelocity.Get(CopyStr(LocationTok, 1, 10), CopyStr(SlowItemTok, 1, 20), '');
        Assert.AreEqual(3, FastVelocity."Rank Value", 'On movements the often-picked item would rank on three.');
        Assert.AreEqual(500, SlowVelocity."Rank Value", 'On quantity the item is ranked on what was moved.');
        Assert.AreEqual(SlowVelocity.Class::WHAClassA, SlowVelocity.Class, 'By quantity the bulk item is the fast one.');
    end;

    [Test]
    procedure AnalysisReplacesThePreviousAnswer()
    var
        ItemVelocity: Record "WHA Item Velocity";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] A velocity is a statement about a period. Two periods added together is a statement
        // about neither, so running the analysis twice must not double the counts.
        ConfigureSlotting(1);
        CreatePick('SLOT-R1', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 2);

        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);
        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);

        ItemVelocity.Get(CopyStr(LocationTok, 1, 10), CopyStr(FastItemTok, 1, 20), '');
        Assert.AreEqual(1, ItemVelocity.Movements, 'The second run should replace the first, not add to it.');
    end;

    [Test]
    procedure AnalysisNeedsALocation()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] Velocity is a comparison between the items at one site. Ranking two warehouses against
        // each other would give the busier one all the class A items.
        ConfigureSlotting(1);

        asserterror SlottingMgt.Analyse('', 0D, 0D);

        Assert.ExpectedError('which location');
    end;

    [Test]
    procedure AFastItemInAPoorBinIsProposedForMoving()
    var
        SlottingProposal: Record "WHA Slotting Proposal";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] This is the finding the feature exists for: the item everybody walks to is at the back
        // of the warehouse.
        ConfigureSlotting(1);
        CreatePick('SLOT-P1', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-P2', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);

        Assert.AreEqual(1, SlottingMgt.Propose(CopyStr(LocationTok, 1, 10)), 'The fast item in the poor bin should be proposed.');

        FindProposalFor(SlottingProposal, CopyStr(FastItemTok, 1, 20));
        Assert.AreEqual(CopyStr(PoorBinTok, 1, 20), SlottingProposal."From Bin Code", 'The proposal should name the bin it is picked from now.');
        Assert.AreEqual('', SlottingProposal."To Bin Code", 'The app does not choose where it should go.');
        Assert.AreEqual(SlottingProposal.Status::WHAOpen, SlottingProposal.Status, 'A new proposal is open.');
    end;

    [Test]
    procedure NothingIsProposedWhenTheBinIsGoodEnough()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] A proposal that tells a warehouse to move stock it has already put in the right place
        // is how people learn to ignore proposals.
        ConfigureSlotting(1);
        CreatePick('SLOT-OK1', CopyStr(FastItemTok, 1, 20), CopyStr(GoodBinTok, 1, 20), 1);
        CreatePick('SLOT-OK2', CopyStr(FastItemTok, 1, 20), CopyStr(GoodBinTok, 1, 20), 1);
        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);

        Assert.AreEqual(0, SlottingMgt.Propose(CopyStr(LocationTok, 1, 10)), 'A fast item in a good bin needs nothing.');
    end;

    [Test]
    procedure TheSameItemIsNotProposedTwiceWhileOneIsOpen()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] Re-running the analysis every week must not build a pile of identical proposals for
        // the item nobody has got round to moving.
        ConfigureSlotting(1);
        CreatePick('SLOT-D1', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-D2', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);
        SlottingMgt.Propose(CopyStr(LocationTok, 1, 10));

        Assert.AreEqual(0, SlottingMgt.Propose(CopyStr(LocationTok, 1, 10)), 'The open proposal should stop a second one.');
    end;

    [Test]
    procedure AcceptingWithADestinationRaisesTheMove()
    var
        SlottingProposal: Record "WHA Slotting Proposal";
        WarehouseTask: Record "WHA Warehouse Task";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
        TaskNo: Code[20];
    begin
        // [SCENARIO] A proposal nobody can act on is a note. Accepting one with somewhere to move to should
        // put the work in the same queue as everything else the floor does.
        ConfigureSlotting(1);
        CreateProposalForFastItem(SlottingProposal);
        SlottingProposal.Validate("To Bin Code", CopyStr(GoodBinTok, 1, 20));
        SlottingProposal.Modify(true);

        TaskNo := SlottingMgt.Accept(SlottingProposal);

        Assert.AreNotEqual('', TaskNo, 'Accepting with a destination should raise the work.');
        WarehouseTask.Get(TaskNo);
        Assert.AreEqual(WarehouseTask."Task Type"::WHAMovement, WarehouseTask."Task Type", 'Re-slotting is a movement.');
        Assert.AreEqual(CopyStr(PoorBinTok, 1, 20), WarehouseTask."From Bin Code", 'It should move from where the item is now.');
        Assert.AreEqual(CopyStr(GoodBinTok, 1, 20), WarehouseTask."To Bin Code", 'It should move to where somebody chose.');
        Assert.AreEqual(SlottingProposal.Status::WHAAccepted, SlottingProposal.Status, 'The proposal should be accepted.');
    end;

    [Test]
    procedure AcceptingWithoutADestinationRecordsTheDecisionOnly()
    var
        SlottingProposal: Record "WHA Slotting Proposal";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] Agreeing that something should move is a decision worth recording even before anybody
        // knows where the space is.
        ConfigureSlotting(1);
        CreateProposalForFastItem(SlottingProposal);

        Assert.AreEqual('', SlottingMgt.Accept(SlottingProposal), 'With nowhere to move to, no work should be raised.');
        Assert.AreEqual(SlottingProposal.Status::WHAAccepted, SlottingProposal.Status, 'The decision should still be recorded.');
        Assert.AreNotEqual('', SlottingProposal."Handled By User ID", 'It should record who answered it.');
    end;

    [Test]
    procedure AnAnsweredProposalIsFinishedWith()
    var
        SlottingProposal: Record "WHA Slotting Proposal";
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        // [SCENARIO] What was suggested and what was decided is the only record of why the stock sits where
        // it sits, so it cannot be answered twice or made to disappear.
        ConfigureSlotting(1);
        CreateProposalForFastItem(SlottingProposal);
        SlottingMgt.Reject(SlottingProposal);

        asserterror SlottingMgt.Accept(SlottingProposal);
        Assert.ExpectedError('already been answered');

        asserterror SlottingProposal.Delete(true);
        Assert.ExpectedError('cannot be deleted');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        SlottingProposal: Record "WHA Slotting Proposal";
        DemoSlotting: Codeunit "WHA Demo Slotting";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] The sample import analyses whatever work exists. Running it twice must not pile up
        // proposals for the same items.
        DemoSlotting.Import();
        CountAfterFirstRun := SlottingProposal.Count();

        DemoSlotting.Import();

        Assert.AreEqual(CountAfterFirstRun, SlottingProposal.Count(), 'A second import should not make more proposals.');
    end;

    local procedure ConfigureSlotting(MinMovements: Integer)
    var
        Setup: Record "WHA Slotting Setup";
        TaskSetup: Record "WHA Warehouse Task Setup";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        Setup.Validate("Min Movements", MinMovements);
        Setup.Validate("Class A Percent", 20);
        Setup.Validate("Class B Percent", 30);
        Setup.Validate("Class A Min Bin Ranking", 80);
        Setup.Validate("Class B Min Bin Ranking", 40);
        Setup.Modify(true);

        TaskSetup.Reset();
        if not TaskSetup.Get() then begin
            TaskSetup.Init();
            TaskSetup.Insert(true);
        end;
        TaskSetup.Validate("Auto Release Tasks", false);
        TaskSetup.Modify(true);

        EnsureLocation(CopyStr(LocationTok, 1, 10));
        EnsureBin(CopyStr(GoodBinTok, 1, 20), 90);
        EnsureBin(CopyStr(PoorBinTok, 1, 20), 10);
        EnsureItem(CopyStr(FastItemTok, 1, 20));
        EnsureItem(CopyStr(SlowItemTok, 1, 20));
        EnsureTaskNoSeries();
    end;

    local procedure CreatePick(TaskNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Task Type" := TaskType::WHAPick;
        WarehouseTask."Location Code" := CopyStr(LocationTok, 1, 10);
        WarehouseTask."From Bin Code" := BinCode;
        WarehouseTask."Item No." := ItemNo;
        WarehouseTask.Quantity := Quantity;
        WarehouseTask."Quantity Handled" := Quantity;
        WarehouseTask.Status := WarehouseTask.Status::WHACompleted;
        WarehouseTask."Completed At" := CurrentDateTime;
        WarehouseTask.Insert(true);
    end;

    local procedure CreateProposalForFastItem(var SlottingProposal: Record "WHA Slotting Proposal")
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        CreatePick('SLOT-X1', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        CreatePick('SLOT-X2', CopyStr(FastItemTok, 1, 20), CopyStr(PoorBinTok, 1, 20), 1);
        SlottingMgt.Analyse(CopyStr(LocationTok, 1, 10), 0D, 0D);
        SlottingMgt.Propose(CopyStr(LocationTok, 1, 10));

        FindProposalFor(SlottingProposal, CopyStr(FastItemTok, 1, 20));
    end;

    local procedure FindProposalFor(var SlottingProposal: Record "WHA Slotting Proposal"; ItemNo: Code[20])
    begin
        SlottingProposal.Reset();
        SlottingProposal.SetRange("Item No.", ItemNo);
        SlottingProposal.FindFirst();
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

    local procedure EnsureBin(BinCode: Code[20]; Ranking: Integer)
    var
        Bin: Record Bin;
    begin
        if Bin.Get(CopyStr(LocationTok, 1, 10), BinCode) then
            exit;

        Bin.Init();
        Bin."Location Code" := CopyStr(LocationTok, 1, 10);
        Bin.Code := BinCode;
        Bin."Bin Ranking" := Ranking;
        Bin.Insert();
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

    local procedure EnsureTaskNoSeries()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        WarehouseSetup: Record "WHA Warehouse Setup";
    begin
        if not NoSeries.Get('WHA-STEST') then begin
            NoSeries.Init();
            NoSeries.Code := 'WHA-STEST';
            NoSeries."Default Nos." := true;
            NoSeries.Insert(true);

            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeries.Code;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'ST000001';
            NoSeriesLine."Ending No." := 'ST999999';
            NoSeriesLine.Insert(true);
        end;

        WarehouseSetup.Reset();
        if not WarehouseSetup.Get() then begin
            WarehouseSetup.Init();
            WarehouseSetup.Insert(true);
        end;
        if WarehouseSetup."Warehouse Task Nos." <> '' then
            exit;

        WarehouseSetup.Validate("Warehouse Task Nos.", 'WHA-STEST');
        WarehouseSetup.Modify(true);
    end;
}
