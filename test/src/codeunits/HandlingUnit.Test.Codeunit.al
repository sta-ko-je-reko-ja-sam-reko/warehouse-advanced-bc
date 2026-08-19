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
