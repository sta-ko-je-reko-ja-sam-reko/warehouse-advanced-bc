codeunit 51008 "WHA Counting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHACOUNT', Locked = true;
        BinTok: Label 'CNT-01', Locked = true;
        ItemTok: Label 'WHA-CNT-IT', Locked = true;

    [Test]
    procedure FillingFromHandlingUnitsTakesWhatEachUnitSaysItHolds()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Selection: Enum "WHA Count Selection";
    begin
        // [SCENARIO] A warehouse whose stock moves as licence-plated units counts the units. What the unit
        // claims to hold is what the count is measured against.
        ConfigureCounting(0, 0);
        StockOnUnit('WHA-CNT-U1', 'A', 6);
        StockOnUnit('WHA-CNT-U2', 'B', 4);
        CreateSheet(CountSheet, 'CNT-FILL', Selection::WHAHandlingUnits, false);

        Assert.AreEqual(2, CountSheetLogic.Fill(CountSheet), 'The sheet should have a line for each thing the units hold.');

        CountSheetLine.SetRange("Sheet No.", 'CNT-FILL');
        CountSheetLine.SetRange("Handling Unit No.", 'WHA-CNT-U1');
        CountSheetLine.FindFirst();
        Assert.AreEqual(6, CountSheetLine."Expected Quantity", 'The expected quantity should be what the unit says it holds.');
        Assert.AreEqual(CopyStr(BinTok, 1, 20), CountSheetLine."Bin Code", 'The line should say where the unit is standing.');
    end;

    [Test]
    procedure ACountThatMatchesLeavesNoDifference()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] The ordinary case. A count that agrees with the system is still a count, and has to be
        // recorded as one.
        ConfigureCounting(0, 0);
        CreateCountingSheet(CountSheet, 'CNT-MATCH', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");

        CountLineLogic.RecordCount(CountSheetLine, 10);

        Assert.IsTrue(CountSheetLine.Counted, 'The line should be counted.');
        Assert.AreEqual(0, CountSheetLine.Variance, 'There should be no difference.');
        Assert.IsFalse(CountSheetLine."Out of Tolerance", 'A line that matches is never out of tolerance.');
    end;

    [Test]
    procedure ACountOfNothingIsStillACount()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] An empty bin is the most important thing a count can find, so zero must not read as
        // not counted yet.
        ConfigureCounting(0, 0);
        CreateCountingSheet(CountSheet, 'CNT-ZERO', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");

        CountLineLogic.RecordCount(CountSheetLine, 0);

        Assert.IsTrue(CountSheetLine.Counted, 'A count of zero should count as counted.');
        Assert.AreEqual(-10, CountSheetLine.Variance, 'The whole expected quantity is missing.');
        Assert.IsTrue(CountSheetLine."Out of Tolerance", 'Nothing where ten was expected is out of tolerance.');
    end;

    [Test]
    procedure ADifferenceInsideThePercentageAllowanceIsNotFlagged()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] A warehouse counting loose goods expects small differences. Flagging every one of them
        // teaches people that the flag means nothing.
        ConfigureCounting(0, 10);
        CreateCountingSheet(CountSheet, 'CNT-PCT', 100);
        GetOnlyLine(CountSheetLine, CountSheet."No.");

        CountLineLogic.RecordCount(CountSheetLine, 95);

        Assert.AreEqual(-5, CountSheetLine.Variance, 'The difference should be recorded even when it is allowed.');
        Assert.IsFalse(CountSheetLine."Out of Tolerance", 'Five in a hundred is inside a ten percent allowance.');
    end;

    [Test]
    procedure ADifferenceBeyondTheAllowanceIsFlagged()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] The tolerance is the line between a rounding difference and a fault worth somebody's
        // attention.
        ConfigureCounting(2, 0);
        CreateCountingSheet(CountSheet, 'CNT-BEYOND', 100);
        GetOnlyLine(CountSheetLine, CountSheet."No.");

        CountLineLogic.RecordCount(CountSheetLine, 90);

        Assert.IsTrue(CountSheetLine."Out of Tolerance", 'Ten missing is more than an allowance of two.');
    end;

    [Test]
    procedure NothingCanBeCountedBeforeTheSheetGoesOut()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        CountLineLogic: Codeunit "WHA Count Line Logic";
        Selection: Enum "WHA Count Selection";
    begin
        // [SCENARIO] Sending the sheet out is what fixes the expected quantities. A count entered before
        // that is measured against a number still being edited.
        ConfigureCounting(0, 0);
        CreateSheet(CountSheet, 'CNT-EARLY', Selection::WHABinContent, false);
        CountSheetLogic.AddLine(CountSheet, CopyStr(BinTok, 1, 20), CopyStr(ItemTok, 1, 20), '', '', '', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");

        asserterror CountLineLogic.RecordCount(CountSheetLine, 9);

        Assert.ExpectedError('nothing on it can be counted');
    end;

    [Test]
    procedure ASheetWithLinesStillUncountedCannotBeMarkedCounted()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        CountLineLogic: Codeunit "WHA Count Line Logic";
        Selection: Enum "WHA Count Selection";
    begin
        // [SCENARIO] A sheet is counted when it has been counted, not when somebody says so.
        ConfigureCounting(0, 0);
        CreateSheet(CountSheet, 'CNT-PARTIAL', Selection::WHABinContent, false);
        CountSheetLogic.AddLine(CountSheet, CopyStr(BinTok, 1, 20), CopyStr(ItemTok, 1, 20), '', '', '', 10);
        CountSheetLogic.AddLine(CountSheet, CopyStr(BinTok, 1, 20), CopyStr(ItemTok, 1, 20), '', '', '', 4);
        CountSheetLogic.Start(CountSheet);

        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 10);

        asserterror CountSheetLogic.Complete(CountSheet);

        Assert.ExpectedError('nobody has counted');
    end;

    [Test]
    procedure ASheetIsMarkedCountedWhenItsLastLineIsCounted()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] Nothing pushes a finished line back to its sheet, so the sheet is asked instead. The
        // answer has to be right when it is asked.
        ConfigureCounting(0, 0);
        CreateCountingSheet(CountSheet, 'CNT-DONE', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 10);

        Assert.IsTrue(CountSheetLogic.CompleteIfCounted(CountSheet), 'A sheet whose lines are all counted should be marked counted.');
        Assert.AreEqual(CountSheet.Status::WHACounted, CountSheet.Status, 'The sheet should be counted.');
        Assert.IsTrue(CountSheet."Counted At" <> 0DT, 'Marking it counted should record when it happened.');
    end;

    [Test]
    procedure ASheetWaitsForItsDifferencesToBeApproved()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] This is the point of a tolerance. A difference nobody has looked at must not be able to
        // leave through the back of the process.
        ConfigureCounting(0, 0);
        CreateCountingSheet(CountSheet, 'CNT-APPROVE', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 7);
        CountSheetLogic.Complete(CountSheet);

        asserterror CountSheetLogic.Close(CountSheet);
        Assert.ExpectedError('nobody has approved');

        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.Approve(CountSheetLine);
        CountSheetLogic.Close(CountSheet);

        Assert.AreEqual(CountSheet.Status::WHAClosed, CountSheet.Status, 'An approved difference should let the sheet close.');
    end;

    [Test]
    procedure CountingALineAgainWithdrawsItsApproval()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] An approval is an approval of a number. Recount the line and it is a different number,
        // which nobody has agreed to yet.
        ConfigureCounting(0, 0);
        CreateCountingSheet(CountSheet, 'CNT-RECOUNT', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 7);
        CountLineLogic.Approve(CountSheetLine);

        CountLineLogic.RecordCount(CountSheetLine, 6);

        Assert.AreEqual(6, CountSheetLine."Counted Quantity", 'The recount should replace the number.');
        Assert.IsFalse(CountSheetLine.Approved, 'The approval of the previous number should be gone.');
        Assert.AreEqual('', CountSheetLine."Approved By User ID", 'Nobody should be recorded as having approved it.');
    end;

    [Test]
    procedure ALineWithinToleranceCannotBeApproved()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] Approving lines that need no approval is how an approval step becomes a habit rather
        // than a decision.
        ConfigureCounting(0, 0);
        CreateCountingSheet(CountSheet, 'CNT-NOAPPR', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 10);

        asserterror CountLineLogic.Approve(CountSheetLine);

        Assert.ExpectedError('within the tolerance');
    end;

    [Test]
    procedure AnEmptySheetCannotBeSentOut()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Selection: Enum "WHA Count Selection";
    begin
        // [SCENARIO] Sending somebody out to count nothing looks like success and is not.
        ConfigureCounting(0, 0);
        CreateSheet(CountSheet, 'CNT-EMPTY', Selection::WHABinContent, false);

        asserterror CountSheetLogic.Start(CountSheet);

        Assert.ExpectedError('no lines');
    end;

    [Test]
    procedure ASheetThatHasBeenCountedCannotBeDeleted()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] What was counted is a record of what was found, and a record that can be deleted is not
        // a record.
        ConfigureCounting(0, 0);
        CreateCountingSheet(CountSheet, 'CNT-KEPT', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 10);
        CountSheetLogic.Complete(CountSheet);

        asserterror CountSheet.Delete(true);

        Assert.ExpectedError('Cancel it instead');
    end;

    [Test]
    procedure DeletingAnOpenSheetTakesItsLinesWithIt()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Selection: Enum "WHA Count Selection";
    begin
        // [SCENARIO] A sheet that was never sent out is a draft. Its lines must not outlive it and turn up
        // on nothing.
        ConfigureCounting(0, 0);
        CreateSheet(CountSheet, 'CNT-DRAFT', Selection::WHABinContent, false);
        CountSheetLogic.AddLine(CountSheet, CopyStr(BinTok, 1, 20), CopyStr(ItemTok, 1, 20), '', '', '', 10);

        CountSheet.Delete(true);

        CountSheetLine.SetRange("Sheet No.", 'CNT-DRAFT');
        Assert.IsTrue(CountSheetLine.IsEmpty(), 'The lines should have gone with the sheet.');
    end;

    [Test]
    procedure ACancelledSheetKeepsWhatWasCounted()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        // [SCENARIO] Cancelling keeps the record, so deleting the cancelled sheet afterwards must not be
        // the way round the guard on deleting a counted one.
        ConfigureCounting(0, 0);
        CreateCountingSheet(CountSheet, 'CNT-WITHDRAWN', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 7);
        CountSheetLogic.Cancel(CountSheet);

        asserterror CountSheet.Delete(true);

        Assert.ExpectedError('lines that have been counted');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        CountSheet: Record "WHA Count Sheet";
        DemoCount: Codeunit "WHA Demo Count";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice creates the sheets once.
        DemoCount.Import();
        CountSheet.SetFilter("No.", 'DEMO-COUNT-*');
        CountAfterFirstRun := CountSheet.Count();

        DemoCount.Import();

        Assert.AreEqual(3, CountAfterFirstRun, 'The first import should create three sample sheets.');
        Assert.AreEqual(CountAfterFirstRun, CountSheet.Count(), 'A second import should not create more sheets.');
    end;

    [Test]
    procedure ClosingASheetHandsEveryDifferenceToThePostingMethod()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        CountLineLogic: Codeunit "WHA Count Line Logic";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Recorder: Codeunit "WHA Test Posting Recorder";
        PostingType: Enum "WHA Posting Type";
    begin
        // [SCENARIO] Closing a sheet is the moment a difference stops being an observation and becomes an
        // adjustment. What the sheet hands over has to be exactly the difference it found, no more.
        ConfigureCounting(0, 0);
        ConfigurePosting();
        Recorder.Forget();
        CreateCountingSheet(CountSheet, 'CNT-POST-1', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 7);
        CountLineLogic.Approve(CountSheetLine);
        CountSheetLogic.Complete(CountSheet);

        CountSheetLogic.Close(CountSheet);

        Assert.AreEqual(1, Recorder.Recorded(TempPostingRequest), 'The one line that differed should have been handed over.');
        TempPostingRequest.FindFirst();
        Assert.AreEqual(PostingType::WHANegativeAdjustment, TempPostingRequest."Posting Type", 'Finding less than expected takes stock away.');
        Assert.AreEqual(3, TempPostingRequest.Quantity, 'The adjustment is the size of the difference, as a positive number.');
        Assert.AreEqual(CountSheet."No.", TempPostingRequest."Document No.", 'The sheet number is what ties the ledger entry back to the count.');
        Assert.AreEqual(CopyStr(LocationTok, 1, 10), TempPostingRequest."Location Code", 'The adjustment belongs at the location the sheet counted.');
    end;

    [Test]
    procedure FindingMoreThanExpectedPutsStockOn()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        CountLineLogic: Codeunit "WHA Count Line Logic";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Recorder: Codeunit "WHA Test Posting Recorder";
        PostingType: Enum "WHA Posting Type";
    begin
        // [SCENARIO] The other direction. A surplus is as much a difference as a shortage, and it has to
        // go the other way.
        ConfigureCounting(0, 0);
        ConfigurePosting();
        Recorder.Forget();
        CreateCountingSheet(CountSheet, 'CNT-POST-2', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 14);
        CountLineLogic.Approve(CountSheetLine);
        CountSheetLogic.Complete(CountSheet);

        CountSheetLogic.Close(CountSheet);

        Recorder.Recorded(TempPostingRequest);
        TempPostingRequest.FindFirst();
        Assert.AreEqual(PostingType::WHAPositiveAdjustment, TempPostingRequest."Posting Type", 'Finding more than expected puts stock on.');
        Assert.AreEqual(4, TempPostingRequest.Quantity, 'The adjustment is the size of the difference.');
    end;

    [Test]
    procedure ASheetThatFoundNoDifferenceAdjustsNothing()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        CountLineLogic: Codeunit "WHA Count Line Logic";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Recorder: Codeunit "WHA Test Posting Recorder";
    begin
        // [SCENARIO] A count that agrees with the system is the ordinary outcome, and it must not raise a
        // zero adjustment for the sake of having posted something.
        ConfigureCounting(0, 0);
        ConfigurePosting();
        Recorder.Forget();
        CreateCountingSheet(CountSheet, 'CNT-POST-3', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 10);
        CountSheetLogic.Complete(CountSheet);

        CountSheetLogic.Close(CountSheet);

        Assert.AreEqual(0, Recorder.Recorded(TempPostingRequest), 'Nothing differed, so nothing should have been handed over.');
        Assert.IsFalse(CountSheet.Posted, 'A sheet that adjusted nothing is not a posted sheet.');
        Assert.AreEqual('', CountSheet."Posting Document No.", 'Nothing was posted, so there is no document to name.');
    end;

    [Test]
    procedure APostedSheetKeepsWhatEachLineAdjusted()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Recorder: Codeunit "WHA Test Posting Recorder";
    begin
        // [SCENARIO] The difference shown on a line today is whatever was counted last. What was adjusted
        // is a separate fact, and the line has to keep it.
        ConfigureCounting(0, 0);
        ConfigurePosting();
        Recorder.Forget();
        CreateCountingSheet(CountSheet, 'CNT-POST-4', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 6);
        CountLineLogic.Approve(CountSheetLine);
        CountSheetLogic.Complete(CountSheet);

        CountSheetLogic.Close(CountSheet);

        Assert.IsTrue(CountSheet.Posted, 'The posting method wrote to the ledger, so the sheet is posted.');
        Assert.AreEqual(CountSheet."No.", CountSheet."Posting Document No.", 'The sheet posts under its own number.');
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        Assert.AreEqual(-4, CountSheetLine."Posting Quantity", 'The line should keep the adjustment it handed over, signed.');
        Assert.IsTrue(CountSheetLine.Posted, 'The line reached the ledger.');
    end;

    [Test]
    procedure ASheetSetToPostNothingStillCloses()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Status: Enum "WHA Count Status";
    begin
        // [SCENARIO] Not posting is a choice, not a missing feature. A warehouse that will not let the app
        // touch its ledger still gets the whole counting process, and the sheet says plainly that nothing
        // was posted.
        ConfigureCounting(0, 0);
        ConfigureNoPosting();
        CreateCountingSheet(CountSheet, 'CNT-POST-5', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 2);
        CountLineLogic.Approve(CountSheetLine);
        CountSheetLogic.Complete(CountSheet);

        CountSheetLogic.Close(CountSheet);

        Assert.AreEqual(Status::WHAClosed, CountSheet.Status, 'The sheet still closes.');
        Assert.IsFalse(CountSheet.Posted, 'Nothing reached the ledger.');
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        Assert.IsFalse(CountSheetLine.Posted, 'The line did not reach the ledger either.');
    end;

    [Test]
    procedure FillingFromHandlingUnitsCarriesTheLotOntoTheLine()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Selection: Enum "WHA Count Selection";
    begin
        // [SCENARIO] A difference on a lot-tracked item cannot be adjusted at all unless the sheet knows
        // which lot was counted. The unit knows; the line has to be told.
        ConfigureCounting(0, 0);
        StockOnUnitWithLot('WHA-CNT-U9', 'LOT-9', 5);
        CreateSheet(CountSheet, 'CNT-LOT', Selection::WHAHandlingUnits, false);

        CountSheetLogic.Fill(CountSheet);

        CountSheetLine.SetRange("Sheet No.", 'CNT-LOT');
        CountSheetLine.SetRange("Handling Unit No.", 'WHA-CNT-U9');
        CountSheetLine.FindFirst();
        Assert.AreEqual('LOT-9', CountSheetLine."Lot No.", 'The line should carry the lot the unit says it holds.');
    end;

    [Test]
    procedure TheDateAnAdjustmentPostedUnderCannotBeMovedAfterwards()
    var
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        CountLineLogic: Codeunit "WHA Count Line Logic";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
    begin
        // [SCENARIO] The date a difference was posted under is part of what was posted. Moving it after
        // the fact would describe a posting that never happened.
        ConfigureCounting(0, 0);
        ConfigureNoPosting();
        CreateCountingSheet(CountSheet, 'CNT-POSTDATE', 10);
        GetOnlyLine(CountSheetLine, CountSheet."No.");
        CountLineLogic.RecordCount(CountSheetLine, 10);
        CountSheetLogic.Complete(CountSheet);
        CountSheetLogic.Close(CountSheet);

        asserterror CountSheet.Validate("Posting Date", CalcDate('<+1D>', WorkDate()));

        Assert.ExpectedError('can no longer be changed');
    end;

    local procedure ConfigureCounting(ToleranceQuantity: Decimal; TolerancePercent: Decimal)
    var
        Setup: Record "WHA Count Setup";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        Setup.Validate("Tolerance Quantity", ToleranceQuantity);
        Setup.Validate("Tolerance Percent", TolerancePercent);
        Setup.Validate("Approve Variances", true);
        Setup.Validate("Blind Counting", false);
        Setup.Modify(true);

        EnsureLocation(CopyStr(LocationTok, 1, 10));
        EnsureItem();
    end;

    local procedure CreateSheet(var CountSheet: Record "WHA Count Sheet"; SheetNo: Code[20]; SheetSelection: Enum "WHA Count Selection"; CountBlind: Boolean)
    begin
        CountSheet.Init();
        CountSheet."No." := SheetNo;
        CountSheet."Location Code" := CopyStr(LocationTok, 1, 10);
        CountSheet.Validate(Selection, SheetSelection);
        CountSheet.Validate(Blind, CountBlind);
        CountSheet.Insert(true);
    end;

    local procedure CreateCountingSheet(var CountSheet: Record "WHA Count Sheet"; SheetNo: Code[20]; ExpectedQuantity: Decimal)
    var
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Selection: Enum "WHA Count Selection";
    begin
        CreateSheet(CountSheet, SheetNo, Selection::WHABinContent, false);
        CountSheetLogic.AddLine(CountSheet, CopyStr(BinTok, 1, 20), CopyStr(ItemTok, 1, 20), '', '', '', ExpectedQuantity);
        CountSheetLogic.Start(CountSheet);
    end;

    local procedure GetOnlyLine(var CountSheetLine: Record "WHA Count Sheet Line"; SheetNo: Code[20])
    begin
        CountSheetLine.Reset();
        CountSheetLine.SetRange("Sheet No.", SheetNo);
        CountSheetLine.FindFirst();
    end;

    local procedure StockOnUnit(UnitNo: Code[20]; LineDescription: Text[100]; Quantity: Decimal)
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit."Location Code" := CopyStr(LocationTok, 1, 10);
        HandlingUnit."Bin Code" := CopyStr(BinTok, 1, 20);
        HandlingUnit.Insert(true);

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Item No." := CopyStr(ItemTok, 1, 20);
        HandlingUnitLine.Description := LineDescription;
        HandlingUnitLine.Quantity := Quantity;
        HandlingUnitLine.Insert(true);
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

    local procedure ConfigurePosting()
    var
        Setup: Record "WHA Count Setup";
        Method: Enum "WHA Posting Method";
    begin
        Setup.Get();
        Setup.Validate("Posting Method", Method::WHATestRecorder);
        Setup.Modify(true);
    end;

    local procedure ConfigureNoPosting()
    var
        Setup: Record "WHA Count Setup";
        Method: Enum "WHA Posting Method";
    begin
        Setup.Get();
        Setup.Validate("Posting Method", Method::WHANone);
        Setup.Modify(true);
    end;

    local procedure StockOnUnitWithLot(UnitNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit."Location Code" := CopyStr(LocationTok, 1, 10);
        HandlingUnit."Bin Code" := CopyStr(BinTok, 1, 20);
        HandlingUnit.Insert(true);

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Item No." := CopyStr(ItemTok, 1, 20);
        HandlingUnitLine."Lot No." := LotNo;
        HandlingUnitLine.Quantity := Quantity;
        HandlingUnitLine.Insert(true);
    end;
}
