codeunit 51000 "WHA Handling Unit Tests"
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
        // [SCENARIO] The sample data exercises every status value, so each is visible on the list.
        DemoHandlingUnit.Import();

        foreach Status in Status.Ordinals() do begin
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
}
