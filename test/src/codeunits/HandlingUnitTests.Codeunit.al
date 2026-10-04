codeunit 59000 "WHA Handling Unit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure LocationChangeClearsBin()
    var
        HandlingUnit: Record "WHA Handling Unit";
        xHandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [SCENARIO] Moving a handling unit to another location clears the bin, so a bin belonging to
        // the previous location cannot be carried over.
        xHandlingUnit."Location Code" := 'BLUE';
        xHandlingUnit."Bin Code" := 'B-01-0001';
        HandlingUnit := xHandlingUnit;
        HandlingUnit."Location Code" := 'RED';

        Logic.Validate_LocationCode(HandlingUnit, xHandlingUnit);

        Assert.AreEqual('', HandlingUnit."Bin Code", 'The bin should be cleared when the location changes.');
    end;

    [Test]
    procedure SameLocationKeepsBin()
    var
        HandlingUnit: Record "WHA Handling Unit";
        xHandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [SCENARIO] Revalidating the same location leaves the bin untouched.
        xHandlingUnit."Location Code" := 'BLUE';
        xHandlingUnit."Bin Code" := 'B-01-0001';
        HandlingUnit := xHandlingUnit;

        Logic.Validate_LocationCode(HandlingUnit, xHandlingUnit);

        Assert.AreEqual('B-01-0001', HandlingUnit."Bin Code", 'The bin should survive when the location is unchanged.');
    end;

    [Test]
    procedure SelfParentIsRejected()
    var
        HandlingUnit: Record "WHA Handling Unit";
        xHandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [SCENARIO] A handling unit cannot be placed inside itself.
        HandlingUnit."No." := 'HU000001';
        HandlingUnit."Parent No." := 'HU000001';

        asserterror Logic.Validate_ParentNo(HandlingUnit, xHandlingUnit);

        Assert.ExpectedError('A handling unit cannot be placed inside itself.');
    end;

    [Test]
    procedure ClearingParentIsAllowed()
    var
        HandlingUnit: Record "WHA Handling Unit";
        xHandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [SCENARIO] Taking a handling unit out of its parent is always permitted, whatever the
        // nesting configuration says.
        xHandlingUnit."No." := 'HU000002';
        xHandlingUnit."Parent No." := 'HU000001';
        HandlingUnit := xHandlingUnit;
        HandlingUnit."Parent No." := '';

        Logic.Validate_ParentNo(HandlingUnit, xHandlingUnit);

        Assert.AreEqual('', HandlingUnit."Parent No.", 'Clearing the parent should not be blocked.');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        HandlingUnit: Record "WHA Handling Unit";
        DemoHandlingUnit: Codeunit "WHA Demo Handling Unit";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice creates the records once. The importer is reachable
        // from both the guided setup wizard and the MCP tool, so a second run must be a no-op.
        DemoHandlingUnit.Import();
        HandlingUnit.SetFilter("No.", 'DEMO-HU-*');
        CountAfterFirstRun := HandlingUnit.Count();

        DemoHandlingUnit.Import();

        Assert.AreEqual(4, CountAfterFirstRun, 'The first import should create four sample handling units.');
        Assert.AreEqual(CountAfterFirstRun, HandlingUnit.Count(), 'A second import should not create more records.');
    end;

    [Test]
    procedure DemoImportCoversEveryStatus()
    var
        HandlingUnit: Record "WHA Handling Unit";
        DemoHandlingUnit: Codeunit "WHA Demo Handling Unit";
        Status: Enum "WHA Handling Unit Status";
    begin
        // [SCENARIO] The sample data exercises every status the handling unit feature itself owns, so
        // each is visible on the list. The hold and scrap values come from quality hold, which seeds its own.
        DemoHandlingUnit.Import();

        foreach Status in Status.Ordinals() do
            if Status.AsInteger() <= Status::WHAShipped.AsInteger() then begin
                HandlingUnit.Reset();
                HandlingUnit.SetFilter("No.", 'DEMO-HU-*');
                HandlingUnit.SetRange(Status, Status);
                Assert.IsFalse(HandlingUnit.IsEmpty(), 'The sample data should include a unit for every status.');
            end;
    end;

    [Test]
    procedure DemoImportNestsAUnit()
    var
        HandlingUnit: Record "WHA Handling Unit";
        DemoHandlingUnit: Codeunit "WHA Demo Handling Unit";
    begin
        // [SCENARIO] The sample data nests one unit inside another, so the nested count is exercised.
        DemoHandlingUnit.Import();

        HandlingUnit.Get('DEMO-HU-001');
        HandlingUnit.CalcFields("Nested Unit Count");

        Assert.AreEqual(1, HandlingUnit."Nested Unit Count", 'The sample pallet should hold one nested carton.');
    end;

    [Test]
    procedure NegativeQuantityIsRejected()
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        xHandlingUnitLine: Record "WHA Handling Unit Line";
        LineLogic: Codeunit "WHA HU Line Logic";
    begin
        // [SCENARIO] A handling unit cannot hold a negative quantity of anything.
        HandlingUnitLine.Quantity := -1;

        asserterror LineLogic.Validate_Quantity(HandlingUnitLine, xHandlingUnitLine);

        Assert.ExpectedError('cannot be negative');
    end;

    [Test]
    procedure SerialLineMustHaveQuantityOne()
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        xHandlingUnitLine: Record "WHA Handling Unit Line";
        LineLogic: Codeunit "WHA HU Line Logic";
    begin
        // [SCENARIO] A serial number identifies exactly one item, so a serial line cannot carry more.
        HandlingUnitLine."Serial No." := 'SN-0001';
        HandlingUnitLine.Quantity := 5;

        asserterror LineLogic.Validate_Quantity(HandlingUnitLine, xHandlingUnitLine);

        Assert.ExpectedError('quantity of one');
    end;

    [Test]
    procedure ChangingItemClearsVariantAndDescription()
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        xHandlingUnitLine: Record "WHA Handling Unit Line";
        LineLogic: Codeunit "WHA HU Line Logic";
    begin
        // [SCENARIO] Changing the item clears the variant, so a variant of the previous item cannot
        // be carried over onto a different item.
        xHandlingUnitLine."Item No." := 'ITEM-A';
        xHandlingUnitLine."Variant Code" := 'RED';
        xHandlingUnitLine.Description := 'Old description';
        HandlingUnitLine := xHandlingUnitLine;
        HandlingUnitLine."Item No." := 'ITEM-B';

        LineLogic.Validate_ItemNo(HandlingUnitLine, xHandlingUnitLine);

        Assert.AreEqual('', HandlingUnitLine."Variant Code", 'The variant should be cleared when the item changes.');
        Assert.AreEqual('', HandlingUnitLine.Description, 'The description should be cleared when the item changes.');
    end;

    [Test]
    procedure ClosedUnitRefusesContents()
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        // [SCENARIO] Once a handling unit is closed it is ready to ship, so its contents are fixed.
        HandlingUnit.Init();
        HandlingUnit."No." := 'TEST-CLOSED';
        HandlingUnit.Status := HandlingUnit.Status::WHAClosed;
        HandlingUnit.Insert(true);

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := HandlingUnit."No.";
        asserterror HandlingUnitLine.Insert(true);

        Assert.ExpectedError('Only an open handling unit can be changed');
    end;

    [Test]
    procedure DeletingUnitRemovesItsContents()
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        // [SCENARIO] Deleting a handling unit takes its content lines with it, leaving no orphans.
        HandlingUnit.Init();
        HandlingUnit."No." := 'TEST-DELETE';
        HandlingUnit.Insert(true);

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := HandlingUnit."No.";
        HandlingUnitLine.Insert(true);

        HandlingUnit.Delete(true);

        HandlingUnitLine.Reset();
        HandlingUnitLine.SetRange("Handling Unit No.", 'TEST-DELETE');
        Assert.IsTrue(HandlingUnitLine.IsEmpty(), 'Deleting a handling unit should remove its content lines.');
    end;

    [Test]
    procedure LineNumbersStepByTenThousand()
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        LineLogic: Codeunit "WHA HU Line Logic";
    begin
        // [SCENARIO] Line numbers leave room for insertion between existing lines.
        HandlingUnit.Init();
        HandlingUnit."No." := 'TEST-LINENO';
        HandlingUnit.Insert(true);

        Assert.AreEqual(10000, LineLogic.GetNextLineNo('TEST-LINENO'), 'The first line should be numbered 10000.');

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := 'TEST-LINENO';
        HandlingUnitLine.Insert(true);

        Assert.AreEqual(20000, LineLogic.GetNextLineNo('TEST-LINENO'), 'The second line should be numbered 20000.');
    end;

    [Test]
    procedure TopLevelUnitHasZeroDepth()
    var
        HandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [SCENARIO] A handling unit with no parent sits at depth zero.
        HandlingUnit."No." := 'HU000001';
        HandlingUnit."Parent No." := '';

        Assert.AreEqual(0, Logic.GetNestingDepth(HandlingUnit), 'A unit with no parent should be at depth zero.');
    end;

    [Test]
    procedure NestingSwitchedOffRefusesAParent()
    var
        HandlingUnit: Record "WHA Handling Unit";
        xHandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [GIVEN] Nesting switched off in the setup
        SetNesting(false, 0);

        // [WHEN] A unit is given a parent
        xHandlingUnit."No." := 'HUT-N1';
        HandlingUnit := xHandlingUnit;
        HandlingUnit."Parent No." := 'HUT-NP';
        asserterror Logic.Validate_ParentNo(HandlingUnit, xHandlingUnit);

        // [THEN] It is refused, naming the unit
        Assert.ExpectedError('Nesting is switched off in the handling unit setup, so HUT-N1 cannot be placed inside another handling unit.');
        SetNesting(true, 0);
    end;

    [Test]
    procedure TheMaximumDepthCountsLevels()
    var
        HandlingUnit: Record "WHA Handling Unit";
        xHandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [SCENARIO] A maximum of two levels allows a carton on a pallet, and refuses a box in that carton.
        // [GIVEN] A maximum depth of two, and a carton already standing on a pallet
        SetNesting(true, 2);
        InsertUnit('HUT-D-PAL', '');
        InsertUnit('HUT-D-CTN', 'HUT-D-PAL');

        // [WHEN] Another carton is put on the pallet
        xHandlingUnit."No." := 'HUT-D-CT2';
        HandlingUnit := xHandlingUnit;
        HandlingUnit."Parent No." := 'HUT-D-PAL';
        Logic.Validate_ParentNo(HandlingUnit, xHandlingUnit);
        // [THEN] That is allowed
        Assert.AreEqual('HUT-D-PAL', HandlingUnit."Parent No.", 'A second level is within a maximum of two.');

        // [WHEN] A box is put in the carton
        xHandlingUnit."No." := 'HUT-D-BOX';
        HandlingUnit := xHandlingUnit;
        HandlingUnit."Parent No." := 'HUT-D-CTN';
        asserterror Logic.Validate_ParentNo(HandlingUnit, xHandlingUnit);
        // [THEN] A third level is refused
        Assert.ExpectedError('Placing HUT-D-BOX inside HUT-D-CTN would exceed the maximum nesting depth of 2.');
        SetNesting(true, 0);
    end;

    [Test]
    procedure AUnitCannotGoInsideSomethingItHolds()
    var
        HandlingUnit: Record "WHA Handling Unit";
        xHandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [GIVEN] A carton standing on a pallet
        SetNesting(true, 0);
        InsertUnit('HUT-C-PAL', '');
        InsertUnit('HUT-C-CTN', 'HUT-C-PAL');

        // [WHEN] The pallet is put inside the carton
        HandlingUnit.Get('HUT-C-PAL');
        xHandlingUnit := HandlingUnit;
        HandlingUnit."Parent No." := 'HUT-C-CTN';
        asserterror Logic.Validate_ParentNo(HandlingUnit, xHandlingUnit);

        // [THEN] It is refused, because that would make a loop
        Assert.ExpectedError('Handling unit HUT-C-PAL cannot be placed inside HUT-C-CTN, because HUT-C-CTN is already inside HUT-C-PAL.');
    end;

    [Test]
    procedure ANestedUnitKnowsHowDeepItIs()
    var
        HandlingUnit: Record "WHA Handling Unit";
        Logic: Codeunit "WHA Handling Unit Logic";
    begin
        // [GIVEN] A box in a carton on a pallet
        InsertUnit('HUT-G-PAL', '');
        InsertUnit('HUT-G-CTN', 'HUT-G-PAL');
        InsertUnit('HUT-G-BOX', 'HUT-G-CTN');

        // [THEN] The carton is one level down and the box two
        HandlingUnit.Get('HUT-G-CTN');
        Assert.AreEqual(1, Logic.GetNestingDepth(HandlingUnit), 'A carton on a pallet is one level down.');
        HandlingUnit.Get('HUT-G-BOX');
        Assert.AreEqual(2, Logic.GetNestingDepth(HandlingUnit), 'A box in that carton is two levels down.');
    end;

    [Test]
    procedure AUnitStillHoldingOthersCannotBeDeleted()
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        // [GIVEN] A pallet with a carton standing on it
        InsertUnit('HUT-X-PAL', '');
        InsertUnit('HUT-X-CTN', 'HUT-X-PAL');

        // [WHEN] The pallet is deleted
        HandlingUnit.Get('HUT-X-PAL');
        asserterror HandlingUnit.Delete(true);

        // [THEN] It is refused, saying how many units are inside
        Assert.ExpectedError('Handling unit HUT-X-PAL cannot be deleted while it still holds 1 nested unit(s).');
    end;

    [Test]
    procedure AUnitWithoutANumberNeedsASeries()
    var
        HandlingUnit: Record "WHA Handling Unit";
        Setup: Record "WHA Handling Unit Setup";
        PreviousSeries: Code[20];
    begin
        // [GIVEN] A setup with no number series
        EnsureHUSetup(Setup);
        PreviousSeries := Setup."Handling Unit Nos.";
        Setup."Handling Unit Nos." := '';
        Setup.Modify(false);

        // [WHEN] A unit is created without a number
        HandlingUnit.Init();
        asserterror HandlingUnit.Insert(true);

        // [THEN] The series is asked for
        Assert.ExpectedError('Set the handling unit number series on the handling unit setup page');
        Setup."Handling Unit Nos." := PreviousSeries;
        Setup.Modify(false);
    end;

    [Test]
    procedure AUnitWithoutANumberTakesTheNextFromItsSeries()
    var
        HandlingUnit: Record "WHA Handling Unit";
        Setup: Record "WHA Handling Unit Setup";
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
    begin
        // [GIVEN] A setup that numbers units from a series of its own
        EnsureHUSetup(Setup);
        Setup."Handling Unit Nos." := NoSeriesMgt.EnsureSeries('WHA-TEST-HUN', 'Test units', 'HUN000001', 'HUN999999');
        Setup.Modify(false);

        // [WHEN] A unit is created without a number
        HandlingUnit.Init();
        HandlingUnit.Insert(true);

        // [THEN] It is numbered from that series
        Assert.IsTrue(CopyStr(HandlingUnit."No.", 1, 3) = 'HUN', 'The unit should be numbered from the setup series.');
    end;

    local procedure SetNesting(AllowNesting: Boolean; MaxDepth: Integer)
    var
        Setup: Record "WHA Handling Unit Setup";
    begin
        EnsureHUSetup(Setup);
        Setup."Allow Nesting" := AllowNesting;
        Setup."Max Nesting Depth" := MaxDepth;
        Setup.Modify(false);
    end;

    local procedure EnsureHUSetup(var Setup: Record "WHA Handling Unit Setup")
    begin
        if Setup.Get() then
            exit;
        Setup.Init();
        Setup.Insert(false);
    end;

    local procedure InsertUnit(UnitNo: Code[20]; ParentNo: Code[20])
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        if HandlingUnit.Get(UnitNo) then
            exit;
        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit."Parent No." := ParentNo;
        HandlingUnit.Insert(false);
    end;
}
