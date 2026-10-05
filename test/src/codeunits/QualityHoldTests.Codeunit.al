codeunit 59009 "WHA Quality Hold Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHAQC', Locked = true;
        BinTok: Label 'QC-01', Locked = true;
        ItemTok: Label 'WHA-QC-ITEM', Locked = true;
        DamageDescTok: Label 'Crushed corner', Locked = true;

    [Test]
    procedure HoldingAUnitTakesItOutOfUse()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] A hold is worth nothing unless the goods actually stop being available. The unit's own
        // status is what every other part of the app already reads, so that is what changes.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-1', '', Status::WHAOpen);

        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100));

        HandlingUnit.Get('QC-UNIT-1');
        Assert.AreEqual(Status::WHAOnHold, HandlingUnit.Status, 'The unit should be on hold.');

        Assert.IsTrue(QualityHoldMgt.ActiveHold('QC-UNIT-1', QualityHold), 'A hold should be on record for the unit.');
        Assert.AreEqual(QualityHold.Status::WHAOnHold, QualityHold.Status, 'The hold should be open.');
        Assert.AreEqual(Status::WHAOpen, QualityHold."Previous Unit Status", 'The hold should remember what the unit was.');
        Assert.AreNotEqual('', QualityHold."Held By User ID", 'The hold should record who placed it.');
        Assert.IsTrue(QualityHold."Held At" <> 0DT, 'The hold should record when it was placed.');
    end;

    [Test]
    procedure NoWorkCanBePlannedForAHeldUnit()
    var
        HandlingUnit: Record "WHA Handling Unit";
        WarehouseTask: Record "WHA Warehouse Task";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] This is the whole feature. A quarantined pallet that an operator can still be sent to
        // fetch is not quarantined.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-WORK', '', Status::WHAOpen);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100));

        WarehouseTask.Init();
        WarehouseTask."No." := 'QC-TASK-1';

        asserterror WarehouseTask.Validate("Handling Unit No.", 'QC-UNIT-WORK');

        Assert.ExpectedError('no work can be planned');
    end;

    [Test]
    procedure HeldStockIsNotCountedAsAvailableStock()
    var
        HandlingUnit: Record "WHA Handling Unit";
        ReplenishmentRule: Record "WHA Replenishment Rule";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] Held goods are standing in the bin and cannot be picked from it. Counting them would
        // leave the pick face empty with its rule satisfied, which is the failure quality hold is supposed
        // to prevent rather than cause.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-STOCK', '', Status::WHAOpen);
        AddContents('QC-UNIT-STOCK', 40);
        CreateReplenishmentRule(ReplenishmentRule);

        Assert.AreEqual(40, ReplenishmentMgt.Measure(ReplenishmentRule), 'The stock should count before the hold.');

        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100));

        Assert.AreEqual(0, ReplenishmentMgt.Measure(ReplenishmentRule), 'Held stock should not count as available.');
    end;

    [Test]
    procedure HoldingAPalletHoldsWhatIsInsideIt()
    var
        Pallet: Record "WHA Handling Unit";
        Carton: Record "WHA Handling Unit";
        CartonHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
        PalletEntryNo: Integer;
    begin
        // [SCENARIO] A pallet nobody may touch whose cartons can still be picked is not on hold. Each unit
        // gets its own hold, so what was stopped can be answered per unit rather than per pallet.
        ConfigureQualityHold(true, true);
        CreateUnit(Pallet, 'QC-PALLET', '', Status::WHAOpen);
        CreateUnit(Carton, 'QC-CARTON', 'QC-PALLET', Status::WHAOpen);

        PalletEntryNo := QualityHoldMgt.Place(Pallet, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100));

        Carton.Get('QC-CARTON');
        Assert.AreEqual(Status::WHAOnHold, Carton.Status, 'The carton inside should be on hold too.');

        Assert.IsTrue(QualityHoldMgt.ActiveHold('QC-CARTON', CartonHold), 'The carton should have its own hold.');
        Assert.AreEqual(PalletEntryNo, CartonHold."Cascaded From Entry No.", 'The carton hold should point at the hold that brought it with it.');
    end;

    [Test]
    procedure NestedUnitsAreLeftAloneWhenTheSetupSaysSo()
    var
        Pallet: Record "WHA Handling Unit";
        Carton: Record "WHA Handling Unit";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] A warehouse that holds the outer unit only is making a deliberate choice, and the
        // setting is the only difference.
        ConfigureQualityHold(false, true);
        CreateUnit(Pallet, 'QC-PALLET-2', '', Status::WHAOpen);
        CreateUnit(Carton, 'QC-CARTON-2', 'QC-PALLET-2', Status::WHAOpen);

        QualityHoldMgt.Place(Pallet, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100));

        Carton.Get('QC-CARTON-2');
        Assert.AreEqual(Status::WHAOpen, Carton.Status, 'The carton should have been left alone.');
        Assert.IsFalse(QualityHoldMgt.IsOnHold('QC-CARTON-2'), 'No hold should exist for the carton.');
    end;

    [Test]
    procedure AUnitAlreadyOnHoldCannotBeHeldAgain()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] Two open holds on one pallet means two people deciding what happens to it.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-TWICE', '', Status::WHAOpen);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100));

        asserterror QualityHoldMgt.Place(HandlingUnit, Reason::WHAInspection, '');

        Assert.ExpectedError('already on hold');
    end;

    [Test]
    procedure AShippedUnitCannotBeHeld()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] The goods have left the building. Holding them here would say they are quarantined
        // when nothing in this warehouse can stop them.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-GONE', '', Status::WHAShipped);

        asserterror QualityHoldMgt.Place(HandlingUnit, Reason::WHAComplaint, '');

        Assert.ExpectedError('already been shipped');
    end;

    [Test]
    procedure AHoldCannotBeLiftedWithoutADecision()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] A hold lifted without a decision puts the goods back into stock by default, which is
        // exactly the outcome the hold existed to prevent.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-NODEC', '', Status::WHAOpen);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHAInspection, '');
        QualityHoldMgt.ActiveHold('QC-UNIT-NODEC', QualityHold);

        asserterror QualityHoldMgt.Release(QualityHold);

        Assert.ExpectedError('decided what happens');
    end;

    [Test]
    procedure AHoldCanBeLiftedWithoutADecisionWhenTheSetupAllowsIt()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] A warehouse that reviews differences another way can switch the gate off — and what
        // actually happened is still recorded, rather than the hold staying on record as undecided.
        ConfigureQualityHold(true, false);
        CreateUnit(HandlingUnit, 'QC-UNIT-FREE', '', Status::WHAOpen);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHAInspection, '');
        QualityHoldMgt.ActiveHold('QC-UNIT-FREE', QualityHold);

        QualityHoldMgt.Release(QualityHold);

        Assert.AreEqual(QualityHold.Disposition::WHAReleaseToStock, QualityHold.Disposition, 'The hold should record what was actually done.');
        HandlingUnit.Get('QC-UNIT-FREE');
        Assert.AreEqual(Status::WHAOpen, HandlingUnit.Status, 'The unit should be available again.');
    end;

    [Test]
    procedure ReleasingToStockPutsTheUnitBackAsItWas()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
        Disposition: Enum "WHA Hold Disposition";
    begin
        // [SCENARIO] A pallet that was closed and ready to ship when somebody stopped it is closed and ready
        // to ship again. Releasing it must not quietly reopen it.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-CLOSED', '', Status::WHAClosed);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHAInspection, '');
        QualityHoldMgt.ActiveHold('QC-UNIT-CLOSED', QualityHold);
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);

        QualityHoldMgt.Release(QualityHold);

        HandlingUnit.Get('QC-UNIT-CLOSED');
        Assert.AreEqual(Status::WHAClosed, HandlingUnit.Status, 'The unit should be closed again, as it was.');
        Assert.AreEqual(QualityHold.Status::WHAReleased, QualityHold.Status, 'The hold should be released.');
        Assert.AreNotEqual('', QualityHold."Released By User ID", 'The hold should record who lifted it.');
    end;

    [Test]
    procedure ScrappingKeepsTheGoodsOutOfUse()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        WarehouseTask: Record "WHA Warehouse Task";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
        Disposition: Enum "WHA Hold Disposition";
    begin
        // [SCENARIO] Written-off goods must not come back through the front door when the hold is lifted.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-SCRAP', '', Status::WHAOpen);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100));
        QualityHoldMgt.ActiveHold('QC-UNIT-SCRAP', QualityHold);
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAScrap);

        QualityHoldMgt.Release(QualityHold);

        HandlingUnit.Get('QC-UNIT-SCRAP');
        Assert.AreEqual(Status::WHAScrapped, HandlingUnit.Status, 'The unit should be scrapped.');

        WarehouseTask.Init();
        WarehouseTask."No." := 'QC-TASK-SCRAP';
        asserterror WarehouseTask.Validate("Handling Unit No.", 'QC-UNIT-SCRAP');
        Assert.ExpectedError('no work can be planned');
    end;

    [Test]
    procedure ReworkOpensTheUnitSoItsContentsCanBeGotAt()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
        Disposition: Enum "WHA Hold Disposition";
    begin
        // [SCENARIO] Goods that are going to be put right have to be got at, and a closed unit is one
        // nobody may add to or take from.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-REWORK', '', Status::WHAClosed);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHAWrongGoods, '');
        QualityHoldMgt.ActiveHold('QC-UNIT-REWORK', QualityHold);
        QualityHoldMgt.Decide(QualityHold, Disposition::WHARework);

        QualityHoldMgt.Release(QualityHold);

        HandlingUnit.Get('QC-UNIT-REWORK');
        Assert.AreEqual(Status::WHAOpen, HandlingUnit.Status, 'The unit should be open so it can be worked on.');
    end;

    [Test]
    procedure ReleasingTheOuterUnitReleasesWhatWasHeldWithIt()
    var
        Pallet: Record "WHA Handling Unit";
        Carton: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        CartonHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
        Disposition: Enum "WHA Hold Disposition";
    begin
        // [SCENARIO] The decision is about the goods, and what was inside the pallet is the same goods. A
        // cascade that holds but does not release would leave cartons quarantined for ever.
        ConfigureQualityHold(true, true);
        CreateUnit(Pallet, 'QC-PALLET-3', '', Status::WHAOpen);
        CreateUnit(Carton, 'QC-CARTON-3', 'QC-PALLET-3', Status::WHAOpen);
        QualityHoldMgt.Place(Pallet, Reason::WHAInspection, '');
        QualityHoldMgt.ActiveHold('QC-PALLET-3', QualityHold);
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);

        QualityHoldMgt.Release(QualityHold);

        Carton.Get('QC-CARTON-3');
        Assert.AreEqual(Status::WHAOpen, Carton.Status, 'The carton should be available again.');
        Assert.IsFalse(QualityHoldMgt.ActiveHold('QC-CARTON-3', CartonHold), 'The carton hold should have been lifted with the pallet.');
    end;

    [Test]
    procedure ACascadedHoldCannotBeLiftedOnItsOwn()
    var
        Pallet: Record "WHA Handling Unit";
        Carton: Record "WHA Handling Unit";
        CartonHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] Letting the carton out of quarantine while the pallet it is standing on is still held
        // is how quarantined goods walk out of a warehouse.
        ConfigureQualityHold(true, true);
        CreateUnit(Pallet, 'QC-PALLET-4', '', Status::WHAOpen);
        CreateUnit(Carton, 'QC-CARTON-4', 'QC-PALLET-4', Status::WHAOpen);
        QualityHoldMgt.Place(Pallet, Reason::WHAInspection, '');
        QualityHoldMgt.ActiveHold('QC-CARTON-4', CartonHold);

        asserterror QualityHoldMgt.Release(CartonHold);

        Assert.ExpectedError('goes with it');
    end;

    [Test]
    procedure AHoldCannotBeDeleted()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] A hold is the record that somebody stopped goods being used. An audit trail that can
        // be deleted is not one.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-KEPT', '', Status::WHAOpen);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100));
        QualityHoldMgt.ActiveHold('QC-UNIT-KEPT', QualityHold);

        asserterror QualityHold.Delete(true);

        Assert.ExpectedError('cannot be deleted');
    end;

    [Test]
    procedure TheDecisionCannotBeChangedAfterTheHoldIsLifted()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
        Disposition: Enum "WHA Hold Disposition";
    begin
        // [SCENARIO] Once the goods have been dealt with, what happened to them is a matter of record
        // rather than of opinion.
        ConfigureQualityHold(true, true);
        CreateUnit(HandlingUnit, 'QC-UNIT-FINAL', '', Status::WHAOpen);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHAInspection, '');
        QualityHoldMgt.ActiveHold('QC-UNIT-FINAL', QualityHold);
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);
        QualityHoldMgt.Release(QualityHold);

        asserterror QualityHoldMgt.Decide(QualityHold, Disposition::WHAScrap);

        Assert.ExpectedError('can no longer be changed');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        QualityHold: Record "WHA Quality Hold";
        DemoQualityHold: Codeunit "WHA Demo Quality Hold";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice places the holds once.
        DemoQualityHold.Import();
        CountAfterFirstRun := QualityHold.Count();

        DemoQualityHold.Import();

        Assert.AreEqual(CountAfterFirstRun, QualityHold.Count(), 'A second import should not place more holds.');
    end;

    [Test]
    procedure ScrappingAUnitWritesOffWhatItWasHolding()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Recorder: Codeunit "WHA Test Posting Recorder";
        Disposition: Enum "WHA Hold Disposition";
        PostingType: Enum "WHA Posting Type";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] Scrapping goods is the one decision that ends them. Marking the pallet is not enough:
        // what it was holding has to leave the ledger as well, or the app and Business Central disagree
        // about stock that no longer exists.
        ConfigureQualityHold(true, true);
        ConfigureWriteOff();
        Recorder.Forget();
        CreateUnit(HandlingUnit, 'WHA-QC-SCR1', '', Status::WHAOpen);
        AddContents('WHA-QC-SCR1', 12);
        QualityHold.Get(QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100)));
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAScrap);

        QualityHoldMgt.Release(QualityHold);

        Assert.AreEqual(1, Recorder.Recorded(TempPostingRequest), 'The one thing the unit held should have been written off.');
        TempPostingRequest.FindFirst();
        Assert.AreEqual(PostingType::WHANegativeAdjustment, TempPostingRequest."Posting Type", 'Scrapped goods leave stock.');
        Assert.AreEqual(12, TempPostingRequest.Quantity, 'The whole quantity on the unit goes.');
        Assert.AreEqual(12, QualityHold."Posted Quantity", 'The hold should record how much it wrote off.');
        Assert.IsTrue(QualityHold.Posted, 'The write-off reached the ledger.');
    end;

    [Test]
    procedure ReleasingGoodsBackIntoStockWritesNothingOff()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Recorder: Codeunit "WHA Test Posting Recorder";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] Only one of the three decisions ends the goods. Releasing them back into stock must
        // not touch the ledger, because nothing about the stock changed.
        ConfigureQualityHold(true, true);
        ConfigureWriteOff();
        Recorder.Forget();
        CreateUnit(HandlingUnit, 'WHA-QC-SCR2', '', Status::WHAOpen);
        AddContents('WHA-QC-SCR2', 8);
        QualityHold.Get(QualityHoldMgt.Place(HandlingUnit, Reason::WHAInspection, ''));
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);

        QualityHoldMgt.Release(QualityHold);

        Assert.AreEqual(0, Recorder.Recorded(TempPostingRequest), 'Goods that go back into stock are written off nowhere.');
        Assert.IsFalse(QualityHold.Posted, 'Nothing was posted.');
    end;

    [Test]
    procedure ScrappingAPalletWritesOffTheCartonInsideItSeparately()
    var
        Pallet: Record "WHA Handling Unit";
        Carton: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        CascadedHold: Record "WHA Quality Hold";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Recorder: Codeunit "WHA Test Posting Recorder";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] A pallet held with a carton on it is two holds, so it is two write-offs under two
        // documents. Rolling them into one would lose which unit the stock actually left.
        ConfigureQualityHold(true, true);
        ConfigureWriteOff();
        Recorder.Forget();
        CreateUnit(Pallet, 'WHA-QC-SCR3', '', Status::WHAOpen);
        AddContents('WHA-QC-SCR3', 5);
        CreateUnit(Carton, 'WHA-QC-SCR4', 'WHA-QC-SCR3', Status::WHAOpen);
        AddContents('WHA-QC-SCR4', 3);
        QualityHold.Get(QualityHoldMgt.Place(Pallet, Reason::WHADamaged, CopyStr(DamageDescTok, 1, 100)));
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAScrap);

        QualityHoldMgt.Release(QualityHold);

        Assert.AreEqual(2, Recorder.Recorded(TempPostingRequest), 'Each unit writes off what it was holding.');
        CascadedHold.SetRange("Cascaded From Entry No.", QualityHold."Entry No.");
        CascadedHold.FindFirst();
        Assert.AreEqual(3, CascadedHold."Posted Quantity", 'The carton writes off its own contents.');
        Assert.AreNotEqual(QualityHold."Posting Document No.", CascadedHold."Posting Document No.", 'Each unit goes under its own document.');
    end;

    [Test]
    procedure AScrapSetToWriteNothingOffStillTakesTheUnitOutOfUse()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] Not writing off is a choice, not a missing feature. The pallet is still finished with
        // as far as the warehouse is concerned; what the ledger believes is somebody else's decision.
        ConfigureQualityHold(true, true);
        ConfigureNoWriteOff();
        CreateUnit(HandlingUnit, 'WHA-QC-SCR5', '', Status::WHAOpen);
        AddContents('WHA-QC-SCR5', 4);
        QualityHold.Get(QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, ''));
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAScrap);

        QualityHoldMgt.Release(QualityHold);

        HandlingUnit.Get('WHA-QC-SCR5');
        Assert.AreEqual(Status::WHAScrapped, HandlingUnit.Status, 'The unit is still scrapped.');
        Assert.IsFalse(QualityHold.Posted, 'Nothing reached the ledger.');
        Assert.AreEqual(0, QualityHold."Posted Quantity", 'Nothing was written off.');
    end;

    [Test]
    procedure HeldGoodsNobodyHasDecidedAboutAreCountedSeparately()
    var
        TempActivitiesCue: Record "WHA Activities Cue";
        HandlingUnit: Record "WHA Handling Unit";
        DecidedUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        QCActivityCues: Codeunit "WHA QC Activity Cues";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
        Status: Enum "WHA Handling Unit Status";
        CountsAfter: Dictionary of [Text, Text];
        CountsBefore: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Goods on hold and goods nobody has decided about are two different numbers. The
        // second is the one that gets forgotten, which is why it earns a tile of its own.
        // Earlier tests in this codeunit leave holds behind, so the tiles are measured by how far they move.
        ConfigureQualityHold(false, true);
        EnableQualityHold();
        QCActivityCues.AddCounts(CountsBefore);
        CreateUnit(HandlingUnit, 'WHA-QC-CUE1', '', Status::WHAOpen);
        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, '');
        CreateUnit(DecidedUnit, 'WHA-QC-CUE2', '', Status::WHAOpen);
        QualityHold.Get(QualityHoldMgt.Place(DecidedUnit, Reason::WHAInspection, ''));
        QualityHoldMgt.Decide(QualityHold, Disposition::WHARework);

        QCActivityCues.AddCounts(CountsAfter);

        Assert.AreEqual(2, CueMoved(CountsBefore, CountsAfter, TempActivitiesCue.FieldNo("WHA Goods On Hold")), 'Both units are still stopped.');
        Assert.AreEqual(1, CueMoved(CountsBefore, CountsAfter, TempActivitiesCue.FieldNo("WHA Holds To Decide")), 'Only one of them is still waiting for a decision.');
    end;

    [Test]
    procedure PlacingAHoldBlocksTheBinWhenTheSetupSaysSo()
    var
        BinContent: Record "Bin Content";
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
        Policy: Enum "WHA Hold Stock Policy";
    begin
        // [SCENARIO] The policy is only ever reached through placing and releasing a hold, so that is the
        // path that has to block and unblock the bin, not just the policy on its own.
        // [GIVEN] Holds set to block the bin, and a unit with contents standing in a bin of its own
        ConfigureQualityHold(false, false);
        UseStockPolicy(Policy::WHABlockBin);
        CreateUnitInBin(HandlingUnit, 'QC-PB-1', '', 'QC-PB-01');
        AddContents('QC-PB-1', 4);
        EnsureBinContent('QC-PB-1');

        // [WHEN] The unit is put on hold
        QualityHold.Get(QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, DamageDescTok));

        // [THEN] Movement in and out of the bin is blocked
        BinContent.Get(CopyStr(LocationTok, 1, 10), 'QC-PB-01', CopyStr(ItemTok, 1, 20), '', '');
        Assert.AreEqual(BinContent."Block Movement"::All, BinContent."Block Movement", 'Placing the hold should block the bin.');

        // [WHEN] The hold is released back to stock
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);
        QualityHoldMgt.Release(QualityHold);

        // [THEN] The bin is free again
        BinContent.Get(CopyStr(LocationTok, 1, 10), 'QC-PB-01', CopyStr(ItemTok, 1, 20), '', '');
        Assert.AreEqual(BinContent."Block Movement"::" ", BinContent."Block Movement", 'Releasing the hold should free the bin.');
        UseStockPolicy(Policy::WHARecordOnly);
    end;

    [Test]
    procedure ReleasingAPalletFreesItsBinEvenWithCartonsHeldInside()
    var
        BinContent: Record "Bin Content";
        Carton: Record "WHA Handling Unit";
        Pallet: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
        Policy: Enum "WHA Hold Stock Policy";
    begin
        // [SCENARIO] Regression. The cartons held with a pallet stand in the pallet's bin. When the pallet
        // was released before its cartons, their holds were still live in that bin, so the pallet's block
        // was kept, and nothing afterwards ever lifted it.
        // [GIVEN] Nested units held with their parent, holds blocking the bin, and a pallet with a carton
        // inside it, both holding goods in the same bin
        ConfigureQualityHold(true, false);
        UseStockPolicy(Policy::WHABlockBin);
        CreateUnitInBin(Pallet, 'QC-PB-2', '', 'QC-PB-02');
        AddContents('QC-PB-2', 6);
        CreateUnitInBin(Carton, 'QC-PB-3', 'QC-PB-2', 'QC-PB-02');
        AddContents('QC-PB-3', 2);
        EnsureBinContent('QC-PB-2');

        // [GIVEN] The pallet put on hold, which holds the carton with it
        QualityHold.Get(QualityHoldMgt.Place(Pallet, Reason::WHAInspection, DamageDescTok));
        Assert.IsTrue(QualityHoldMgt.IsOnHold('QC-PB-3'), 'The carton is held with the pallet.');

        // [WHEN] The pallet is released back to stock
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);
        QualityHoldMgt.Release(QualityHold);

        // [THEN] The carton is released with it and the bin is free again
        Assert.IsFalse(QualityHoldMgt.IsOnHold('QC-PB-3'), 'The carton is released with the pallet.');
        BinContent.Get(CopyStr(LocationTok, 1, 10), 'QC-PB-02', CopyStr(ItemTok, 1, 20), '', '');
        Assert.AreEqual(BinContent."Block Movement"::" ", BinContent."Block Movement", 'Releasing the pallet should free its bin once its cartons are released too.');
        UseStockPolicy(Policy::WHARecordOnly);
    end;

    [Test]
    procedure RecordingTheHoldOnlyLeavesTheBinAlone()
    var
        BinContent: Record "Bin Content";
        HandlingUnit: Record "WHA Handling Unit";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
        Policy: Enum "WHA Hold Stock Policy";
    begin
        // [GIVEN] Holds set to be recorded only, and a unit with contents in a bin of its own
        ConfigureQualityHold(false, false);
        UseStockPolicy(Policy::WHARecordOnly);
        CreateUnitInBin(HandlingUnit, 'QC-PB-4', '', 'QC-PB-04');
        AddContents('QC-PB-4', 1);
        EnsureBinContent('QC-PB-4');

        // [WHEN] The unit is put on hold
        QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, DamageDescTok);

        // [THEN] Business Central's bin is not touched
        BinContent.Get(CopyStr(LocationTok, 1, 10), 'QC-PB-04', CopyStr(ItemTok, 1, 20), '', '');
        Assert.AreEqual(BinContent."Block Movement"::" ", BinContent."Block Movement", 'Recording a hold only blocks nothing.');
    end;

    [Test]
    procedure HoldingALotBlocksTheLotUntilTheHoldIsReleased()
    var
        HandlingUnit: Record "WHA Handling Unit";
        LotNoInformation: Record "Lot No. Information";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
        Policy: Enum "WHA Hold Stock Policy";
    begin
        // [GIVEN] Holds set to block the lot, and a unit holding a lot nobody has recorded information for
        ConfigureQualityHold(false, false);
        UseStockPolicy(Policy::WHABlockLot);
        if LotNoInformation.Get(CopyStr(ItemTok, 1, 20), '', 'LOT-QC-1') then
            LotNoInformation.Delete(false);
        CreateUnitInBin(HandlingUnit, 'QC-LOT-1', '', 'QC-LOT-01');
        AddContentsWithLot('QC-LOT-1', 'LOT-QC-1', 5);

        // [WHEN] The unit is put on hold
        QualityHold.Get(QualityHoldMgt.Place(HandlingUnit, Reason::WHAComplaint, DamageDescTok));

        // [THEN] The lot is recorded and blocked
        Assert.IsTrue(LotNoInformation.Get(CopyStr(ItemTok, 1, 20), '', 'LOT-QC-1'), 'Holding the lot records it.');
        Assert.IsTrue(LotNoInformation.Blocked, 'Holding the lot blocks it.');

        // [WHEN] The hold is released back to stock
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);
        QualityHoldMgt.Release(QualityHold);

        // [THEN] The lot is unblocked
        LotNoInformation.Get(CopyStr(ItemTok, 1, 20), '', 'LOT-QC-1');
        Assert.IsFalse(LotNoInformation.Blocked, 'Releasing the hold unblocks the lot.');
        UseStockPolicy(Policy::WHARecordOnly);
    end;

    [Test]
    procedure ALotStaysBlockedWhileAnotherHoldStandsOnIt()
    var
        FirstUnit: Record "WHA Handling Unit";
        SecondUnit: Record "WHA Handling Unit";
        LotNoInformation: Record "Lot No. Information";
        FirstHold: Record "WHA Quality Hold";
        SecondHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
        Policy: Enum "WHA Hold Stock Policy";
    begin
        // [GIVEN] Holds set to block the lot, and two units of the same lot both on hold
        ConfigureQualityHold(false, false);
        UseStockPolicy(Policy::WHABlockLot);
        CreateUnitInBin(FirstUnit, 'QC-LOT-2', '', 'QC-LOT-02');
        AddContentsWithLot('QC-LOT-2', 'LOT-QC-2', 3);
        CreateUnitInBin(SecondUnit, 'QC-LOT-3', '', 'QC-LOT-03');
        AddContentsWithLot('QC-LOT-3', 'LOT-QC-2', 4);
        FirstHold.Get(QualityHoldMgt.Place(FirstUnit, Reason::WHAComplaint, DamageDescTok));
        SecondHold.Get(QualityHoldMgt.Place(SecondUnit, Reason::WHAComplaint, DamageDescTok));

        // [WHEN] The first hold is released
        QualityHoldMgt.Decide(FirstHold, Disposition::WHAReleaseToStock);
        QualityHoldMgt.Release(FirstHold);

        // [THEN] The lot stays blocked, because the second unit is still being questioned
        LotNoInformation.Get(CopyStr(ItemTok, 1, 20), '', 'LOT-QC-2');
        Assert.IsTrue(LotNoInformation.Blocked, 'Another hold still stands on the lot.');

        // [WHEN] The second hold is released
        QualityHoldMgt.Decide(SecondHold, Disposition::WHAReleaseToStock);
        QualityHoldMgt.Release(SecondHold);

        // [THEN] The lot is free
        LotNoInformation.Get(CopyStr(ItemTok, 1, 20), '', 'LOT-QC-2');
        Assert.IsFalse(LotNoInformation.Blocked, 'With no hold left on it, the lot is unblocked.');
        UseStockPolicy(Policy::WHARecordOnly);
    end;

    [Test]
    procedure AUnitThatIsNotThereCannotBeHeld()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
    begin
        // [GIVEN] A unit number nobody has created
        ConfigureQualityHold(false, false);
        HandlingUnit.Init();
        HandlingUnit."No." := 'QC-NOWHERE';

        // [WHEN] It is put on hold
        asserterror QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, DamageDescTok);

        // [THEN] It is refused, naming the unit
        Assert.ExpectedError('Handling unit QC-NOWHERE does not exist, so it cannot be put on hold.');
    end;

    [Test]
    procedure AScrappedUnitCannotBeHeldAgain()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
    begin
        // [GIVEN] A unit that has been scrapped
        ConfigureQualityHold(false, false);
        CreateUnit(HandlingUnit, 'QC-SCRAPPED', '', HandlingUnit.Status::WHAScrapped);

        // [WHEN] It is put on hold
        asserterror QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, DamageDescTok);

        // [THEN] It is refused, because nothing is left to hold
        Assert.ExpectedError('has been scrapped, so there is nothing left to hold');
    end;

    [Test]
    procedure AHoldCannotBeReleasedTwice()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Disposition: Enum "WHA Hold Disposition";
        Reason: Enum "WHA Hold Reason";
    begin
        // [GIVEN] A hold that has been released
        ConfigureQualityHold(false, false);
        CreateUnit(HandlingUnit, 'QC-TWICE', '', HandlingUnit.Status::WHAOpen);
        QualityHold.Get(QualityHoldMgt.Place(HandlingUnit, Reason::WHADamaged, DamageDescTok));
        QualityHoldMgt.Decide(QualityHold, Disposition::WHAReleaseToStock);
        QualityHoldMgt.Release(QualityHold);

        // [WHEN] It is released again
        asserterror QualityHoldMgt.Release(QualityHold);

        // [THEN] It is refused
        Assert.ExpectedError('so it cannot be released again');
    end;

    [Test]
    procedure EachDecisionSaysWhetherTheGoodsComeBackOrGo()
    var
        HoldDisposition: Interface "WHA IHoldDisposition";
        Disposition: Enum "WHA Hold Disposition";
    begin
        // [SCENARIO] Whether a decision gives the goods back and whether it writes them off are what the
        // write-off and the unit status follow, so each decision has to answer both the right way.
        // [THEN] Pending neither returns nor writes off
        HoldDisposition := Disposition::WHAPending;
        Assert.IsFalse(HoldDisposition.ReturnsToUse(), 'Pending returns nothing to use.');
        Assert.IsFalse(HoldDisposition.WritesOffStock(), 'Pending writes nothing off.');
        // [THEN] Releasing to stock returns the goods and writes nothing off
        HoldDisposition := Disposition::WHAReleaseToStock;
        Assert.IsTrue(HoldDisposition.ReturnsToUse(), 'Releasing returns the goods to use.');
        Assert.IsFalse(HoldDisposition.WritesOffStock(), 'Releasing writes nothing off.');
        // [THEN] Rework returns the goods and writes nothing off
        HoldDisposition := Disposition::WHARework;
        Assert.IsTrue(HoldDisposition.ReturnsToUse(), 'Rework returns the goods to use.');
        Assert.IsFalse(HoldDisposition.WritesOffStock(), 'Rework writes nothing off.');
        // [THEN] Scrapping keeps the goods out and writes them off
        HoldDisposition := Disposition::WHAScrap;
        Assert.IsFalse(HoldDisposition.ReturnsToUse(), 'Scrap does not return the goods.');
        Assert.IsTrue(HoldDisposition.WritesOffStock(), 'Scrap writes the goods off.');
    end;

    [Test]
    procedure TheDefaultReasonComesFromTheSetup()
    var
        Setup: Record "WHA Quality Hold Setup";
        QualityHoldMgt: Codeunit "WHA Quality Hold Mgt.";
        Reason: Enum "WHA Hold Reason";
    begin
        // [GIVEN] A setup whose default reason is a complaint
        ConfigureQualityHold(false, false);
        Setup.Get();
        Setup.Validate("Default Reason", Reason::WHAComplaint);
        Setup.Modify(true);

        // [THEN] A new hold suggests a complaint
        Assert.AreEqual(Reason::WHAComplaint, QualityHoldMgt.DefaultReason(), 'The default reason is read from the setup.');

        // [GIVEN] No setup at all
        Setup.Delete(false);
        // [THEN] A new hold suggests an inspection
        Assert.AreEqual(Reason::WHAInspection, QualityHoldMgt.DefaultReason(), 'Without a setup a hold is an inspection.');
        ConfigureQualityHold(false, false);
    end;

    local procedure UseStockPolicy(Policy: Enum "WHA Hold Stock Policy")
    var
        Setup: Record "WHA Quality Hold Setup";
    begin
        Setup.Get();
        Setup."Hold Blocks Stock" := Policy;
        Setup.Modify(false);
    end;

    local procedure CreateUnitInBin(var HandlingUnit: Record "WHA Handling Unit"; UnitNo: Code[20]; ParentNo: Code[20]; BinCode: Code[20])
    begin
        CreateUnit(HandlingUnit, UnitNo, ParentNo, HandlingUnit.Status::WHAOpen);
        HandlingUnit."Bin Code" := BinCode;
        HandlingUnit.Modify(false);
    end;

    local procedure AddContentsWithLot(UnitNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Item No." := CopyStr(ItemTok, 1, 20);
        HandlingUnitLine."Lot No." := LotNo;
        HandlingUnitLine.Quantity := Quantity;
        HandlingUnitLine.Insert(true);
    end;

    local procedure ConfigureQualityHold(HoldNested: Boolean; RequireDisposition: Boolean)
    var
        Setup: Record "WHA Quality Hold Setup";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        Setup.Validate("Hold Nested Units", HoldNested);
        Setup.Validate("Require Disposition", RequireDisposition);
        Setup.Modify(true);

        EnsureLocation(CopyStr(LocationTok, 1, 10));
    end;

    local procedure CreateUnit(var HandlingUnit: Record "WHA Handling Unit"; UnitNo: Code[20]; ParentNo: Code[20]; UnitStatus: Enum "WHA Handling Unit Status")
    begin
        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit."Location Code" := CopyStr(LocationTok, 1, 10);
        HandlingUnit."Bin Code" := CopyStr(BinTok, 1, 20);
        HandlingUnit."Parent No." := ParentNo;
        HandlingUnit.Status := UnitStatus;
        HandlingUnit.Insert(true);
    end;

    local procedure AddContents(UnitNo: Code[20]; Quantity: Decimal)
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Item No." := CopyStr(ItemTok, 1, 20);
        HandlingUnitLine.Quantity := Quantity;
        HandlingUnitLine.Insert(true);
    end;

    local procedure CreateReplenishmentRule(var ReplenishmentRule: Record "WHA Replenishment Rule")
    var
        Method: Enum "WHA Repl. Method";
    begin
        ReplenishmentRule.Init();
        ReplenishmentRule."Location Code" := CopyStr(LocationTok, 1, 10);
        ReplenishmentRule."Item No." := CopyStr(ItemTok, 1, 20);
        ReplenishmentRule."Bin Code" := CopyStr(BinTok, 1, 20);
        ReplenishmentRule.Validate(Method, Method::WHAHandlingUnits);
        ReplenishmentRule.Validate("Maximum Quantity", 100);
        ReplenishmentRule.Validate("Minimum Quantity", 10);
        ReplenishmentRule.Insert(true);
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

    local procedure ConfigureWriteOff()
    var
        Setup: Record "WHA Quality Hold Setup";
        Method: Enum "WHA Posting Method";
    begin
        Setup.Get();
        Setup.Validate("Posting Method", Method::WHATestRecorder);
        Setup.Modify(true);
    end;

    local procedure ConfigureNoWriteOff()
    var
        Setup: Record "WHA Quality Hold Setup";
        Method: Enum "WHA Posting Method";
    begin
        Setup.Get();
        Setup.Validate("Posting Method", Method::WHANone);
        Setup.Modify(true);
    end;

    local procedure EnableQualityHold()
    var
        Setup: Record "WHA Quality Hold Setup";
    begin
        Setup.Get();
        Setup."WHA Enabled" := true;
        Setup.Modify(true);
    end;
    [Test]
    procedure RecordingTheHoldOnlyTouchesNothingInBusinessCentral()
    var
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        HoldRecordsOnly: Codeunit "WHA Hold Records Only";
    begin
        // [SCENARIO] The value a fresh install and every upgrade lands on. Business Central goes on
        // offering the goods, and the setup page says so rather than leaving it to be discovered.
        Assert.AreEqual(0, HoldRecordsOnly.Apply(QualityHold, HandlingUnit), 'Recording the hold only should block nothing.');
        Assert.AreEqual(0, HoldRecordsOnly.Lift(QualityHold, HandlingUnit), 'Recording the hold only should release nothing.');
        Assert.AreNotEqual('', HoldRecordsOnly.Describe(), 'Every policy should say what it does.');
    end;

    [Test]
    procedure EveryHoldStockPolicyExplainsHowFarItReaches()
    var
        HoldBlocksBin: Codeunit "WHA Hold Blocks Bin";
        HoldBlocksLot: Codeunit "WHA Hold Blocks Lot";
    begin
        // [SCENARIO] Blocking a lot reaches every warehouse in the company and blocking a bin reaches
        // everything else standing in it. Neither may be chosen without the page saying so.
        Assert.AreNotEqual('', HoldBlocksBin.Describe(), 'Blocking the bin should say what it does.');
        Assert.AreNotEqual('', HoldBlocksLot.Describe(), 'Blocking the lot should say what it does.');
    end;

    [Test]
    procedure BlockingABinStopsMovementBothWays()
    var
        BinContent: Record "Bin Content";
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        HoldBlocksBin: Codeunit "WHA Hold Blocks Bin";
    begin
        // [SCENARIO] Goods under investigation should not be added to either, or the quantity being
        // questioned changes while somebody is questioning it.
        EnsureLocation(CopyStr(LocationTok, 1, 10));
        CreateUnitInBin(HandlingUnit, 'QC-BLK-1', '', 'QC-BLK-01');
        AddContents('QC-BLK-1', 4);
        EnsureBinContent('QC-BLK-1');

        Assert.AreEqual(1, HoldBlocksBin.Apply(QualityHold, HandlingUnit), 'The bin content should have been blocked.');

        BinContent.Get(HandlingUnit."Location Code", HandlingUnit."Bin Code", CopyStr(ItemTok, 1, 20), '', '');
        Assert.AreEqual(BinContent."Block Movement"::All, BinContent."Block Movement", 'A held bin should be blocked in both directions.');
    end;

    [Test]
    procedure ReleasingGivesTheBinBackWhenNobodyElseIsHoldingIt()
    var
        BinContent: Record "Bin Content";
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        HoldBlocksBin: Codeunit "WHA Hold Blocks Bin";
    begin
        // [SCENARIO] Scrapping is not a reason to leave the block standing: what is scrapped is written
        // off by posting, and a bin left blocked afterwards holds back the good stock still in it.
        EnsureLocation(CopyStr(LocationTok, 1, 10));
        CreateUnitInBin(HandlingUnit, 'QC-BLK-2', '', 'QC-BLK-02');
        AddContents('QC-BLK-2', 4);
        EnsureBinContent('QC-BLK-2');
        HoldBlocksBin.Apply(QualityHold, HandlingUnit);

        Assert.AreEqual(1, HoldBlocksBin.Lift(QualityHold, HandlingUnit), 'The bin content should have been released.');

        BinContent.Get(HandlingUnit."Location Code", HandlingUnit."Bin Code", CopyStr(ItemTok, 1, 20), '', '');
        Assert.AreEqual(BinContent."Block Movement"::" ", BinContent."Block Movement", 'A released bin should move again.');
    end;

    [Test]
    procedure ABinIsNotGivenBackWhileAnotherHoldStandsOnIt()
    var
        BinContent: Record "Bin Content";
        HandlingUnit: Record "WHA Handling Unit";
        QualityHold: Record "WHA Quality Hold";
        HoldBlocksBin: Codeunit "WHA Hold Blocks Bin";
    begin
        // [SCENARIO] Business Central blocks a bin, not a pallet, so two pallets in one bin share one
        // block. Releasing the first must not free stock the second is still questioning.
        EnsureLocation(CopyStr(LocationTok, 1, 10));
        CreateUnitInBin(HandlingUnit, 'QC-BLK-3', '', 'QC-BLK-03');
        AddContents('QC-BLK-3', 4);
        EnsureBinContent('QC-BLK-3');

        InsertLiveHold(99001, HandlingUnit);
        QualityHold.Get(99001);
        HoldBlocksBin.Apply(QualityHold, HandlingUnit);

        InsertLiveHold(99002, HandlingUnit);

        Assert.AreEqual(0, HoldBlocksBin.Lift(QualityHold, HandlingUnit), 'A second live hold on the same bin should keep the block.');

        BinContent.Get(HandlingUnit."Location Code", HandlingUnit."Bin Code", CopyStr(ItemTok, 1, 20), '', '');
        Assert.AreEqual(BinContent."Block Movement"::All, BinContent."Block Movement", 'The bin should still be blocked.');
    end;

    local procedure CueMoved(CountsBefore: Dictionary of [Text, Text]; CountsAfter: Dictionary of [Text, Text]; CueFieldNo: Integer): Integer
    var
        AfterCount: Integer;
        BeforeCount: Integer;
    begin
        Evaluate(BeforeCount, CountsBefore.Get(Format(CueFieldNo)));
        Evaluate(AfterCount, CountsAfter.Get(Format(CueFieldNo)));
        exit(AfterCount - BeforeCount);
    end;

    local procedure InsertLiveHold(EntryNo: Integer; var HandlingUnit: Record "WHA Handling Unit")
    var
        QualityHold: Record "WHA Quality Hold";
    begin
        QualityHold.Init();
        QualityHold."Entry No." := EntryNo;
        QualityHold."Handling Unit No." := HandlingUnit."No.";
        QualityHold."Location Code" := HandlingUnit."Location Code";
        QualityHold."Bin Code" := HandlingUnit."Bin Code";
        QualityHold.Status := QualityHold.Status::WHAOnHold;
        QualityHold.Insert(false);
    end;

    local procedure EnsureBinContent(UnitNo: Code[20])
    var
        BinContent: Record "Bin Content";
        HandlingUnit: Record "WHA Handling Unit";
    begin
        HandlingUnit.Get(UnitNo);

        if BinContent.Get(HandlingUnit."Location Code", HandlingUnit."Bin Code", CopyStr(ItemTok, 1, 20), '', '') then
            exit;

        BinContent.Init();
        BinContent."Location Code" := HandlingUnit."Location Code";
        BinContent."Bin Code" := HandlingUnit."Bin Code";
        BinContent."Item No." := CopyStr(ItemTok, 1, 20);
        BinContent.Insert(false);
    end;

}
