codeunit 51006 "WHA Packing Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHAPACK', Locked = true;
        StationTok: Label 'PACK-01', Locked = true;
        ItemTok: Label 'WHA-PACK-ITEM', Locked = true;

    [Test]
    procedure StartingOpensACartonAtTheBench()
    var
        PackSession: Record "WHA Pack Session";
        HandlingUnit: Record "WHA Handling Unit";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] A carton is a handling unit from the first moment, so everything the rest of the app
        // knows about handling units applies to it without packing having to repeat any of it.
        ConfigurePacking(true, true);

        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));

        Assert.AreNotEqual('', PackSession."Handling Unit No.", 'Starting should open a carton.');
        Assert.AreEqual(PackSession.Status::WHAPacking, PackSession.Status, 'A new session should be packing.');
        Assert.AreNotEqual('', PackSession."Packed By User ID", 'The session should record who is packing.');

        HandlingUnit.Get(PackSession."Handling Unit No.");
        Assert.AreEqual(LocationTok, HandlingUnit."Location Code", 'The carton should be at the bench location.');
    end;

    [Test]
    procedure PackingAtABlockedBenchIsRefused()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] A bench taken out of use stays out of use.
        ConfigurePacking(true, true);
        CreateStation('PACK-DEAD', true);

        asserterror PackLogic.Start(PackSession, 'PACK-DEAD');

        Assert.ExpectedError('out of use');
    end;

    [Test]
    procedure PackingAtABenchNobodyRegisteredIsRefused()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] The bench decides where the carton is, so an unknown one would produce a carton
        // nowhere in particular.
        ConfigurePacking(true, true);

        asserterror PackLogic.Start(PackSession, 'PACK-NOWHERE');

        Assert.ExpectedError('no packing station');
    end;

    [Test]
    procedure GoodsGoIntoTheCarton()
    var
        PackSession: Record "WHA Pack Session";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] What is packed becomes the contents of the handling unit, which is where everything
        // downstream already looks.
        ConfigurePacking(true, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));

        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 3);
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 2);

        HandlingUnitLine.SetRange("Handling Unit No.", PackSession."Handling Unit No.");
        Assert.AreEqual(2, HandlingUnitLine.Count(), 'Both lines should be in the carton.');

        PackSession.CalcFields("Total Quantity");
        Assert.AreEqual(5, PackSession."Total Quantity", 'The session should show what is in the carton.');
    end;

    [Test]
    procedure PackingNothingIsRefused()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] A line with no item or no quantity is a keystroke, not a thing in a box.
        ConfigurePacking(true, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));

        asserterror PackLogic.PackItem(PackSession, '', '', 5);

        Assert.ExpectedError('what is going into the carton');
    end;

    [Test]
    procedure AnEmptyCartonCannotBeClosed()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] Closing an empty carton tells everybody downstream that something was packed.
        ConfigurePacking(false, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));

        asserterror PackLogic.Close(PackSession);

        Assert.ExpectedError('is empty');
    end;

    [Test]
    procedure AnUncheckedCartonCannotBeClosedWhenTheSetupAsksForAChecK()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] Verification means somebody looked. If it can be skipped it means nothing.
        ConfigurePacking(true, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 1);

        asserterror PackLogic.Close(PackSession);

        Assert.ExpectedError('has not been checked');
    end;

    [Test]
    procedure ACartonCanBeClosedWithoutACheckWhenTheSetupAllowsIt()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] A warehouse that has decided speed matters more than a second pair of eyes can say
        // so, once, in setup.
        ConfigurePacking(false, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 1);

        PackLogic.Close(PackSession);

        Assert.AreEqual(PackSession.Status::WHAClosed, PackSession.Status, 'The carton should close without a check when the setup allows it.');
    end;

    [Test]
    procedure CheckingRecordsWhoChecked()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] Who packed and who checked are recorded separately, because in a warehouse that
        // takes verification seriously they are two different people.
        ConfigurePacking(true, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 1);

        PackLogic.Verify(PackSession);

        Assert.AreEqual(PackSession.Status::WHAVerified, PackSession.Status, 'Checking should mark the session verified.');
        Assert.AreNotEqual('', PackSession."Verified By User ID", 'Checking should record who checked.');
    end;

    [Test]
    procedure AnEmptyCartonCannotBeChecked()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] There is nothing to look at.
        ConfigurePacking(true, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));

        asserterror PackLogic.Verify(PackSession);

        Assert.ExpectedError('is empty');
    end;

    [Test]
    procedure ClosingTheCartonClosesTheHandlingUnit()
    var
        PackSession: Record "WHA Pack Session";
        HandlingUnit: Record "WHA Handling Unit";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] The carton has been taped shut, so the handling unit should stop accepting contents
        // as well. Otherwise the system would let somebody add to a box that is already on a pallet.
        ConfigurePacking(true, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 1);
        PackLogic.Verify(PackSession);

        PackLogic.Close(PackSession);

        HandlingUnit.Get(PackSession."Handling Unit No.");
        Assert.AreEqual(HandlingUnit.Status::WHAClosed, HandlingUnit.Status, 'Closing the carton should close the handling unit.');
    end;

    [Test]
    procedure TheHandlingUnitCanBeLeftOpenWhenTheSetupSaysSo()
    var
        PackSession: Record "WHA Pack Session";
        HandlingUnit: Record "WHA Handling Unit";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] A warehouse that tops cartons up later can say so, and the unit stays open.
        ConfigurePacking(false, false);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 1);

        PackLogic.Close(PackSession);

        HandlingUnit.Get(PackSession."Handling Unit No.");
        Assert.AreEqual(HandlingUnit.Status::WHAOpen, HandlingUnit.Status, 'The unit should stay open when the setup says so.');
    end;

    [Test]
    procedure NothingGoesIntoAClosedCarton()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] The box is taped. Anything added now is in the system and not in the box.
        ConfigurePacking(false, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 1);
        PackLogic.Close(PackSession);

        asserterror PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 1);

        Assert.ExpectedError('nothing more can go into the carton');
    end;

    [Test]
    procedure AbandoningLeavesTheCartonAsItIs()
    var
        PackSession: Record "WHA Pack Session";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        PackLogic: Codeunit "WHA Pack Session Logic";
        CartonNo: Code[20];
    begin
        // [SCENARIO] Walking away from a half-packed carton must not make its contents disappear —
        // somebody has to be able to find the box and deal with what is in it.
        ConfigurePacking(true, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 4);
        CartonNo := PackSession."Handling Unit No.";

        PackLogic.Cancel(PackSession);

        Assert.AreEqual(PackSession.Status::WHACancelled, PackSession.Status, 'Abandoning should mark the session.');

        HandlingUnitLine.SetRange("Handling Unit No.", CartonNo);
        Assert.IsFalse(HandlingUnitLine.IsEmpty(), 'What was already packed should still be in the carton.');
    end;

    [Test]
    procedure AClosedSessionCannotBeDeleted()
    var
        PackSession: Record "WHA Pack Session";
        PackLogic: Codeunit "WHA Pack Session Logic";
    begin
        // [SCENARIO] It produced a carton that may already have left the building. What happened is a
        // record.
        ConfigurePacking(false, true);
        PackLogic.Start(PackSession, CopyStr(StationTok, 1, 20));
        PackLogic.PackItem(PackSession, CopyStr(ItemTok, 1, 20), '', 1);
        PackLogic.Close(PackSession);

        asserterror PackSession.Delete(true);

        Assert.ExpectedError('Cancel it instead');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        PackStation: Record "WHA Pack Station";
        PackSession: Record "WHA Pack Session";
        DemoPack: Codeunit "WHA Demo Pack";
        SessionsAfterFirstRun: Integer;
    begin
        // [SCENARIO] Importing the sample data twice creates the benches and the worked example once.
        DemoPack.Import();
        PackStation.SetFilter("Code", 'DEMO-PACK-*');
        PackSession.SetRange("Station Code", 'DEMO-PACK-01');
        SessionsAfterFirstRun := PackSession.Count();

        DemoPack.Import();

        Assert.AreEqual(3, PackStation.Count(), 'The first import should create three sample benches.');
        Assert.AreEqual(SessionsAfterFirstRun, PackSession.Count(), 'A second import should not pack another carton.');
    end;

    local procedure ConfigurePacking(RequireVerification: Boolean; CloseUnit: Boolean)
    var
        Setup: Record "WHA Pack Setup";
    begin
        EnsureLocation();
        EnsureItem();
        CreateStation(CopyStr(StationTok, 1, 20), false);

        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;

        Setup.Validate("Require Verification", RequireVerification);
        Setup.Validate("Close Unit When Closed", CloseUnit);
        Setup.Modify(true);

        EnsureUnitNumbering();
    end;

    local procedure CreateStation(StationCode: Code[20]; IsBlocked: Boolean)
    var
        PackStation: Record "WHA Pack Station";
    begin
        if PackStation.Get(StationCode) then
            exit;

        PackStation.Init();
        PackStation."Code" := StationCode;
        PackStation."Location Code" := CopyStr(LocationTok, 1, 10);
        PackStation.Blocked := IsBlocked;
        PackStation.Insert(true);
    end;

    local procedure EnsureUnitNumbering()
    var
        HandlingUnitSetup: Record "WHA Handling Unit Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SeriesCode: Code[20];
    begin
        SeriesCode := 'WHA-PACK-HU';

        if not NoSeries.Get(SeriesCode) then begin
            NoSeries.Init();
            NoSeries.Code := SeriesCode;
            NoSeries.Description := SeriesCode;
            NoSeries."Default Nos." := true;
            NoSeries.Insert();

            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := SeriesCode;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'PHU00001';
            NoSeriesLine."Ending No." := 'PHU99999';
            NoSeriesLine.Insert();
        end;

        HandlingUnitSetup.Reset();
        if not HandlingUnitSetup.Get() then begin
            HandlingUnitSetup.Init();
            HandlingUnitSetup.Insert(true);
        end;
        HandlingUnitSetup.Validate("Handling Unit Nos.", SeriesCode);
        HandlingUnitSetup.Modify(true);
    end;

    local procedure EnsureLocation()
    var
        Location: Record Location;
    begin
        if Location.Get(LocationTok) then
            exit;

        Location.Init();
        Location.Code := CopyStr(LocationTok, 1, MaxStrLen(Location.Code));
        Location.Insert();
    end;

    local procedure EnsureItem()
    var
        Item: Record Item;
    begin
        if Item.Get(ItemTok) then
            exit;

        Item.Init();
        Item."No." := CopyStr(ItemTok, 1, MaxStrLen(Item."No."));
        Item.Description := CopyStr(ItemTok, 1, MaxStrLen(Item.Description));
        Item.Insert();
    end;
}
