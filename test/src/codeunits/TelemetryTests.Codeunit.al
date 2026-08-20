codeunit 51018 "WHA Telemetry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure AFinishedRunReportsItsNameAndACount()
    var
        Telemetry: Codeunit "WHA Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A run that did nothing every night for a month has to look different from the
        // outside to one that is working, and the count is what makes it look different.
        Dimensions := Telemetry.RunDimensions('Top up pick bins', 7);

        Assert.AreEqual('Top up pick bins', Dimensions.Get('WhaRun'), 'The run should say what it was.');
        Assert.AreEqual('7', Dimensions.Get('WhaHandled'), 'The run should say how much it did.');
    end;

    [Test]
    procedure ARunThatDidNothingSaysSoRatherThanSayingNothing()
    var
        Telemetry: Codeunit "WHA Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Zero is a finding, not an absence. It has to be reported as a number.
        Dimensions := Telemetry.RunDimensions('Capture KPI snapshots', 0);

        Assert.AreEqual('0', Dimensions.Get('WhaHandled'), 'A run that handled nothing should report zero.');
    end;

    [Test]
    procedure ACountIsReportedTheSameWayInEveryCountry()
    var
        Telemetry: Codeunit "WHA Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Telemetry is read by somebody who is not in this company's region. A count formatted
        // for the session's language would sort and parse differently depending on who ran the job.
        Dimensions := Telemetry.RunDimensions('Measure finished work', 1234567);

        Assert.AreEqual('1234567', Dimensions.Get('WhaHandled'), 'The count should be invariant, with no thousands separator.');
    end;

    [Test]
    procedure ASkippedRunReportsWhyItStopped()
    var
        Telemetry: Codeunit "WHA Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A run that refused is not the same as a run that found nothing, and telling the two
        // apart from the outside is the whole point.
        Dimensions := Telemetry.SkipDimensions('Re-measure velocity and propose moves', 'Nothing has moved at this location');

        Assert.AreEqual('Re-measure velocity and propose moves', Dimensions.Get('WhaRun'), 'The run should say what it was.');
        Assert.AreEqual('Nothing has moved at this location', Dimensions.Get('WhaReason'), 'The run should say why it stopped.');
    end;

    [Test]
    procedure NothingButTheRunAndItsOutcomeLeavesTheTenant()
    var
        Telemetry: Codeunit "WHA Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Telemetry leaves the customer's tenant. What this app sends is fixed by the shape of
        // the procedures — there is no parameter through which an item, a lot, a document, a bin or a
        // person could reach it — and this asserts the resulting dimension set is exactly that and no more.
        Dimensions := Telemetry.RunDimensions('Release waves from templates', 3);
        Assert.AreEqual(2, Dimensions.Count(), 'A finished run should report the run and the count, and nothing else.');

        Clear(Dimensions);
        Dimensions := Telemetry.SkipDimensions('Release waves from templates', 'Nothing has moved at this location');
        Assert.AreEqual(2, Dimensions.Count(), 'A skipped run should report the run and the reason, and nothing else.');
    end;
}
