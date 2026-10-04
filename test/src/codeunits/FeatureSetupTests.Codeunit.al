namespace WarehouseAdvanced.Test;

using Microsoft.Foundation.NoSeries;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using WarehouseAdvanced.Analytics;
using WarehouseAdvanced.Core;
using WarehouseAdvanced.Counting;
using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.DockYard;
using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Integration;
using WarehouseAdvanced.LabourManagement;
using WarehouseAdvanced.Slotting;
using WarehouseAdvanced.WaveManagement;

codeunit 59019 "WHA Feature Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        FeatureMsg: Label '%1: %2', Locked = true;

    [Test]
    procedure EveryFeatureOffersExactlyOneSetupStep()
    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        FeatureSetup: Interface "WHA IFeatureSetup";
        Feature: Enum "WHA Feature";
        Ordinal: Integer;
    begin
        // [SCENARIO] The guided setup list is built by asking every feature for its own step. A feature
        // that added none would be impossible to switch on from the hub; one that added two would show twice.
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            Feature := Enum::"WHA Feature".FromInteger(Ordinal);
            if Feature <> Feature::WHANone then begin
                // [GIVEN] An empty step buffer
                TempSetupStep.Reset();
                TempSetupStep.DeleteAll();
                FeatureSetup := Feature;

                // [WHEN] The feature registers its step
                FeatureSetup.RegisterStep(TempSetupStep);

                // [THEN] There is exactly one step, it names the feature, has a toggle and opens a setup page
                Assert.AreEqual(1, TempSetupStep.Count(), StrSubstNo(FeatureMsg, Feature, 'it should add exactly one step.'));
                TempSetupStep.FindFirst();
                Assert.AreEqual(Feature, TempSetupStep.Feature, StrSubstNo(FeatureMsg, Feature, 'The step of it should name its own feature.'));
                Assert.IsTrue(TempSetupStep."Has Toggle", StrSubstNo(FeatureMsg, Feature, 'it can be switched on and off, so its step has a toggle.'));
                Assert.AreNotEqual(0, TempSetupStep."Setup Page ID", StrSubstNo(FeatureMsg, Feature, 'The step of it should open its setup page.'));
                Assert.AreNotEqual('', TempSetupStep.Name, StrSubstNo(FeatureMsg, Feature, 'The step of it should have a name.'));
            end;
        end;
    end;

    [Test]
    procedure EveryFeatureStepHasItsOwnPlaceInTheList()
    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        FeatureSetup: Interface "WHA IFeatureSetup";
        Ordinal: Integer;
    begin
        // [SCENARIO] Steps are keyed by their number. Two features that picked the same number would make
        // the hub fail to open, which is exactly what this would surface as a duplicate-key error.
        // [GIVEN] One shared step buffer
        // [WHEN] Every feature registers into it
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            FeatureSetup := Enum::"WHA Feature".FromInteger(Ordinal);
            FeatureSetup.RegisterStep(TempSetupStep);
        end;

        // [THEN] Every feature but the none value has its own row
        Assert.AreEqual(Enum::"WHA Feature".Ordinals().Count() - 1, TempSetupStep.Count(), 'Every feature should have a step of its own number.');
    end;

    [Test]
    procedure TheWizardSwitchesEveryFeatureOnAndOff()
    var
        FeatureSetup: Interface "WHA IFeatureSetup";
        Feature: Enum "WHA Feature";
        Ordinal: Integer;
        WasEnabled: Boolean;
    begin
        // [SCENARIO] The wizard's toggle is the only switch most users will ever touch. Each feature
        // must honour it both ways, through its own setup record.
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            Feature := Enum::"WHA Feature".FromInteger(Ordinal);
            if Feature <> Feature::WHANone then begin
                FeatureSetup := Feature;
                WasEnabled := FeatureSetup.IsEnabled();

                // [WHEN] The wizard switches the feature on
                FeatureSetup.ApplyChoices(true, false, false);
                // [THEN] The feature says it is on
                Assert.IsTrue(FeatureSetup.IsEnabled(), StrSubstNo(FeatureMsg, Feature, 'it should be on after the wizard switched it on.'));

                // [WHEN] The wizard switches it off again
                FeatureSetup.ApplyChoices(false, false, false);
                // [THEN] The feature says it is off
                Assert.IsFalse(FeatureSetup.IsEnabled(), StrSubstNo(FeatureMsg, Feature, 'it should be off after the wizard switched it off.'));
                FeatureSetup.ApplyChoices(WasEnabled, false, false);
            end;
        end;
    end;

    [Test]
    procedure AFeatureNobodySetUpIsSwitchedOff()
    var
        Setup: Record "WHA Handling Unit Setup";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        // [GIVEN] No handling unit setup record at all
        Setup.DeleteAll();

        // [WHEN] Somebody asks whether the feature is on
        // [THEN] The answer is no, rather than an error about a missing record
        Assert.IsFalse(FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAHandlingUnits), 'A feature with no setup record is switched off.');
    end;

    [Test]
    procedure TheApplicationAreaFollowsEveryFeature()
    var
        TempApplicationAreaSetup: Record "Application Area Setup" temporary;
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        FeatureSetup: Interface "WHA IFeatureSetup";
        Feature: Enum "WHA Feature";
        Ordinal: Integer;
        WasEnabled: Boolean;
    begin
        // [SCENARIO] The operational pages of a feature only appear when its application area is on, and
        // each feature switches its own area through a subscriber. A subscriber that read the wrong
        // feature would show one feature's pages when another was switched on.
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            Feature := Enum::"WHA Feature".FromInteger(Ordinal);
            if Feature <> Feature::WHANone then begin
                FeatureSetup := Feature;
                WasEnabled := FeatureSetup.IsEnabled();

                // [GIVEN] The feature is switched on
                FeatureSetup.ApplyChoices(true, false, false);
                // [WHEN] Business Central works out the application areas
                TempApplicationAreaSetup.Init();
                ApplicationAreaMgmtFacade.GetEssentialExperienceAppAreas(TempApplicationAreaSetup);
                // [THEN] The feature's own area is on
                Assert.IsTrue(AppAreaOf(TempApplicationAreaSetup, Feature), StrSubstNo(FeatureMsg, Feature, 'The application area of it should be on with the feature.'));

                // [GIVEN] The feature is switched off
                FeatureSetup.ApplyChoices(false, false, false);
                // [WHEN] The areas are worked out again
                TempApplicationAreaSetup.Init();
                ApplicationAreaMgmtFacade.GetEssentialExperienceAppAreas(TempApplicationAreaSetup);
                // [THEN] The area is off
                Assert.IsFalse(AppAreaOf(TempApplicationAreaSetup, Feature), StrSubstNo(FeatureMsg, Feature, 'The application area of it should be off with the feature.'));
                FeatureSetup.ApplyChoices(WasEnabled, false, false);
            end;
        end;
    end;

    [Test]
    procedure CreatingNumberingGivesEachFeatureItsOwnSeries()
    var
        CountSetup: Record "WHA Count Setup";
        DockSetup: Record "WHA Dock Setup";
        HandlingUnitSetup: Record "WHA Handling Unit Setup";
        TaskSetup: Record "WHA Warehouse Task Setup";
        WaveSetup: Record "WHA Wave Setup";
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        // [GIVEN] No setup record for any of the features that number their documents
        CountSetup.DeleteAll();
        DockSetup.DeleteAll();
        HandlingUnitSetup.DeleteAll();
        TaskSetup.DeleteAll();
        WaveSetup.DeleteAll();

        // [WHEN] The wizard is told to create the numbering for each
        FeatureSetup := Enum::"WHA Feature"::WHAHandlingUnits;
        FeatureSetup.ApplyChoices(true, true, false);
        FeatureSetup := Enum::"WHA Feature"::WHADirectedWork;
        FeatureSetup.ApplyChoices(true, true, false);
        FeatureSetup := Enum::"WHA Feature"::WHAWaveManagement;
        FeatureSetup.ApplyChoices(true, true, false);
        FeatureSetup := Enum::"WHA Feature"::WHACounting;
        FeatureSetup.ApplyChoices(true, true, false);
        FeatureSetup := Enum::"WHA Feature"::WHADockYard;
        FeatureSetup.ApplyChoices(true, true, false);

        // [THEN] Each feature's setup points at its own series, and each series exists with a line
        HandlingUnitSetup.Get();
        AssertSeries('WHA-HU', HandlingUnitSetup."Handling Unit Nos.");
        TaskSetup.Get();
        AssertSeries('WHA-TASK', TaskSetup."Warehouse Task Nos.");
        WaveSetup.Get();
        AssertSeries('WHA-WAVE', WaveSetup."Wave Nos.");
        CountSetup.Get();
        AssertSeries('WHA-COUNT', CountSetup."Count Sheet Nos.");
        DockSetup.Get();
        AssertSeries('WHA-DOCK', DockSetup."Dock Appointment Nos.");
    end;

    [Test]
    procedure NumberingSomebodyAlreadyChoseIsKept()
    var
        HandlingUnitSetup: Record "WHA Handling Unit Setup";
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
        FeatureSetup: Interface "WHA IFeatureSetup";
        ChosenSeries: Code[20];
    begin
        // [GIVEN] Handling units already numbered from a series somebody picked by hand
        FeatureSetup := Enum::"WHA Feature"::WHAHandlingUnits;
        FeatureSetup.ApplyChoices(true, false, false);
        ChosenSeries := NoSeriesMgt.EnsureSeries('WHA-TEST-HU', 'Chosen by hand', 'TST0001', 'TST9999');
        HandlingUnitSetup.Get();
        HandlingUnitSetup.Validate("Handling Unit Nos.", ChosenSeries);
        HandlingUnitSetup.Modify(true);

        // [WHEN] The wizard is run again and asked to create the numbering
        FeatureSetup.ApplyChoices(true, true, false);

        // [THEN] The series somebody chose is left in place
        HandlingUnitSetup.Get();
        Assert.AreEqual(ChosenSeries, HandlingUnitSetup."Handling Unit Nos.", 'The wizard must not replace a series somebody already chose.');
    end;

    [Test]
    procedure AFirstSetupStartsFromSensibleDefaults()
    var
        AnalyticsSetup: Record "WHA Analytics Setup";
        CountSetup: Record "WHA Count Setup";
        HandlingUnitSetup: Record "WHA Handling Unit Setup";
        IntegrationSetup: Record "WHA Integration Setup";
        LabourSetup: Record "WHA Labour Setup";
        SlottingSetup: Record "WHA Slotting Setup";
        TaskSetup: Record "WHA Warehouse Task Setup";
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        // [GIVEN] None of these features has ever been set up
        AnalyticsSetup.DeleteAll();
        CountSetup.DeleteAll();
        HandlingUnitSetup.DeleteAll();
        IntegrationSetup.DeleteAll();
        LabourSetup.DeleteAll();
        SlottingSetup.DeleteAll();
        TaskSetup.DeleteAll();

        // [WHEN] The wizard runs for each, leaving the feature off
        FeatureSetup := Enum::"WHA Feature"::WHAAnalytics;
        FeatureSetup.ApplyChoices(false, false, false);
        FeatureSetup := Enum::"WHA Feature"::WHACounting;
        FeatureSetup.ApplyChoices(false, false, false);
        FeatureSetup := Enum::"WHA Feature"::WHAHandlingUnits;
        FeatureSetup.ApplyChoices(false, false, false);
        FeatureSetup := Enum::"WHA Feature"::WHAIntegration;
        FeatureSetup.ApplyChoices(false, false, false);
        FeatureSetup := Enum::"WHA Feature"::WHALabourManagement;
        FeatureSetup.ApplyChoices(false, false, false);
        FeatureSetup := Enum::"WHA Feature"::WHASlotting;
        FeatureSetup.ApplyChoices(false, false, false);
        FeatureSetup := Enum::"WHA Feature"::WHADirectedWork;
        FeatureSetup.ApplyChoices(false, false, false);

        // [THEN] Each setup record exists and starts from the documented defaults
        AnalyticsSetup.Get();
        Assert.AreEqual(14, AnalyticsSetup."Catch Up Days", 'Analytics catches up two weeks by default.');
        CountSetup.Get();
        Assert.IsTrue(CountSetup."Blind Counting", 'Counting is blind by default.');
        Assert.AreEqual(2, CountSetup."Tolerance Percent", 'Counting tolerates two percent by default.');
        Assert.IsTrue(CountSetup."Approve Variances", 'Differences need approval by default.');
        HandlingUnitSetup.Get();
        Assert.IsTrue(HandlingUnitSetup."Allow Nesting", 'Handling units may be nested by default.');
        IntegrationSetup.Get();
        Assert.IsTrue(IntegrationSetup."Release Requested Work", 'Requested work is released by default.');
        Assert.AreEqual(3, IntegrationSetup."Max Retry Count", 'A message is retried three times by default.');
        LabourSetup.Get();
        Assert.AreEqual(240, LabourSetup."Max Job Minutes", 'A job longer than four hours is not believed by default.');
        Assert.AreEqual(30, LabourSetup."Look Back Days", 'Labour looks back thirty days by default.');
        SlottingSetup.Get();
        Assert.AreEqual(90, SlottingSetup."Analysis Period Days", 'Slotting looks at ninety days by default.');
        Assert.AreEqual(20, SlottingSetup."Class A Percent", 'Class A is the top twenty percent by default.');
        Assert.AreEqual(30, SlottingSetup."Class B Percent", 'Class B is the next thirty percent by default.');
        TaskSetup.Get();
        Assert.AreEqual(100, TaskSetup."Default Priority", 'A task starts in the middle of the priority range by default.');
    end;

    [Test]
    procedure RunningTheWizardAgainKeepsWhatTheUserChanged()
    var
        CountSetup: Record "WHA Count Setup";
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        // [GIVEN] Counting set up, with a tolerance the user changed from the default
        FeatureSetup := Enum::"WHA Feature"::WHACounting;
        FeatureSetup.ApplyChoices(true, false, false);
        CountSetup.Get();
        CountSetup."Tolerance Percent" := 7;
        CountSetup."Blind Counting" := false;
        CountSetup.Modify(true);

        // [WHEN] The wizard runs again
        FeatureSetup.ApplyChoices(true, false, false);

        // [THEN] The defaults are not written back over what the user chose
        CountSetup.Get();
        Assert.AreEqual(7, CountSetup."Tolerance Percent", 'The wizard must not reset the tolerance.');
        Assert.IsFalse(CountSetup."Blind Counting", 'The wizard must not reset blind counting.');
    end;

    [Test]
    procedure ASeriesIsCreatedWithItsFirstLine()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
        SeriesCode: Code[20];
    begin
        // [GIVEN] A series code nobody has used
        if NoSeries.Get('WHA-TEST-NEW') then
            NoSeries.Delete(true);

        // [WHEN] The series is ensured
        SeriesCode := NoSeriesMgt.EnsureSeries('WHA-TEST-NEW', 'Test series', 'TN0001', 'TN9999');

        // [THEN] It exists as a default series with one line running between the given numbers
        Assert.AreEqual('WHA-TEST-NEW', SeriesCode, 'The code of the series is answered.');
        NoSeries.Get(SeriesCode);
        Assert.AreEqual('Test series', NoSeries.Description, 'The series carries its description.');
        Assert.IsTrue(NoSeries."Default Nos.", 'The series hands out numbers by default.');
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        Assert.AreEqual(1, NoSeriesLine.Count(), 'The series has one line.');
        NoSeriesLine.FindFirst();
        Assert.AreEqual('TN0001', NoSeriesLine."Starting No.", 'The line starts at the given number.');
        Assert.AreEqual('TN9999', NoSeriesLine."Ending No.", 'The line ends at the given number.');
    end;

    [Test]
    procedure AnExistingSeriesIsLeftAsItIs()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
    begin
        // [GIVEN] A series that already exists
        NoSeriesMgt.EnsureSeries('WHA-TEST-OLD', 'Original', 'OL0001', 'OL9999');

        // [WHEN] It is ensured again with different values
        NoSeriesMgt.EnsureSeries('WHA-TEST-OLD', 'Changed', 'XX0001', 'XX9999');

        // [THEN] Nothing about it changed and no second line was added
        NoSeries.Get('WHA-TEST-OLD');
        Assert.AreEqual('Original', NoSeries.Description, 'An existing series keeps its description.');
        NoSeriesLine.SetRange("Series Code", 'WHA-TEST-OLD');
        Assert.AreEqual(1, NoSeriesLine.Count(), 'An existing series gets no extra line.');
        NoSeriesLine.FindFirst();
        Assert.AreEqual('OL0001', NoSeriesLine."Starting No.", 'An existing series keeps its numbers.');
    end;

    [Test]
    procedure ACodeLongerThanASeriesCodeIsCutToFit()
    var
        NoSeries: Record "No. Series";
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
        SeriesCode: Code[20];
    begin
        // [WHEN] A series is asked for under a code longer than twenty characters
        SeriesCode := NoSeriesMgt.EnsureSeries('WHA-TEST-ABCDEFGHIJKLMNOP', 'Too long', 'LG0001', 'LG9999');

        // [THEN] The series is created under the first twenty characters, and that is the code answered
        Assert.AreEqual('WHA-TEST-ABCDEFGHIJK', SeriesCode, 'The code is cut to the length of a series code.');
        Assert.IsTrue(NoSeries.Get(SeriesCode), 'The series exists under the shortened code.');
    end;

    [Test]
    procedure UsingAFeatureThatIsOffIsRefused()
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        // [SCENARIO] The API pages call this before every write, so it is what keeps the flag
        // authoritative outside the UI.
        // [GIVEN] Handling units switched off
        FeatureSetup := Enum::"WHA Feature"::WHAHandlingUnits;
        FeatureSetup.ApplyChoices(false, false, false);

        // [WHEN] Something checks that the feature is on
        asserterror FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAHandlingUnits);

        // [THEN] It is refused, naming the feature
        Assert.ExpectedError('The Handling units feature is not enabled.');
    end;

    [Test]
    procedure UsingAFeatureThatIsOnIsAllowed()
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        // [GIVEN] Handling units switched on
        FeatureSetup := Enum::"WHA Feature"::WHAHandlingUnits;
        FeatureSetup.ApplyChoices(true, false, false);

        // [WHEN] Something checks that the feature is on
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAHandlingUnits);

        // [THEN] Nothing is raised
        Assert.IsTrue(FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAHandlingUnits), 'The feature is on and the check let it through.');
    end;

    [Test]
    procedure TheFoundationRecordIsCreatedOnce()
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        // [GIVEN] No foundation record
        WarehouseSetup.DeleteAll();
        Assert.IsFalse(SetupLogic.IsComplete(), 'Without the record the foundation is not complete.');

        // [WHEN] The record is ensured twice
        SetupLogic.EnsureExists(WarehouseSetup);
        SetupLogic.EnsureExists(WarehouseSetup);

        // [THEN] There is exactly one, and the foundation is complete
        WarehouseSetup.Reset();
        Assert.AreEqual(1, WarehouseSetup.Count(), 'Ensuring twice leaves one record.');
        Assert.IsTrue(SetupLogic.IsComplete(), 'With the record the foundation is complete.');
    end;

    [Test]
    procedure AValueWithNoFeatureBehindItDoesNothing()
    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        // [GIVEN] The none value, which binds the default implementation
        FeatureSetup := Enum::"WHA Feature"::WHANone;

        // [WHEN] It is asked to register, apply and describe itself
        FeatureSetup.RegisterStep(TempSetupStep);
        FeatureSetup.ApplyChoices(true, true, true);
        FeatureSetup.RegisterMcpConfiguration();

        // [THEN] It adds no step and stays switched off
        Assert.IsTrue(TempSetupStep.IsEmpty(), 'The none value adds no setup step.');
        Assert.IsFalse(FeatureSetup.IsEnabled(), 'The none value is never switched on, whatever it was told.');
    end;

    [Test]
    procedure TheHubListsTheFoundationFirstAndThenEveryFeature()
    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        WarehouseSetup: Record "WHA Warehouse Setup";
        GuidedSetup: Codeunit "WHA Guided Setup";
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        // [GIVEN] The foundation record exists
        SetupLogic.EnsureExists(WarehouseSetup);

        // [WHEN] The hub builds its list
        GuidedSetup.PopulateSteps(TempSetupStep);

        // [THEN] The foundation comes first, has no toggle, is always on and is complete, and every
        // feature follows with a step of its own
        Assert.AreEqual(Enum::"WHA Feature".Ordinals().Count(), TempSetupStep.Count(), 'One step for the foundation and one for each feature.');
        TempSetupStep.FindFirst();
        Assert.AreEqual(10, TempSetupStep."Step No.", 'The foundation is the first step.');
        Assert.IsFalse(TempSetupStep."Has Toggle", 'The foundation cannot be switched off.');
        Assert.IsTrue(TempSetupStep.Enabled, 'The foundation is always on.');
        Assert.AreEqual(Enum::"WHA Setup Step Status"::WHACompleted, TempSetupStep.Status, 'An existing foundation record makes the step complete.');
    end;

    [Test]
    procedure TheHubShowsWhichFeaturesAreOn()
    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        GuidedSetup: Codeunit "WHA Guided Setup";
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        // [GIVEN] Handling units on and counting off
        FeatureSetup := Enum::"WHA Feature"::WHAHandlingUnits;
        FeatureSetup.ApplyChoices(true, false, false);
        FeatureSetup := Enum::"WHA Feature"::WHACounting;
        FeatureSetup.ApplyChoices(false, false, false);

        // [WHEN] The hub builds its list
        GuidedSetup.PopulateSteps(TempSetupStep);

        // [THEN] The handling unit step is complete and the counting step is not started
        TempSetupStep.SetRange(Feature, Enum::"WHA Feature"::WHAHandlingUnits);
        TempSetupStep.FindFirst();
        Assert.IsTrue(TempSetupStep.Enabled, 'The handling unit step shows the feature as on.');
        Assert.AreEqual(Enum::"WHA Setup Step Status"::WHACompleted, TempSetupStep.Status, 'A feature that is on is a completed step.');
        TempSetupStep.SetRange(Feature, Enum::"WHA Feature"::WHACounting);
        TempSetupStep.FindFirst();
        Assert.IsFalse(TempSetupStep.Enabled, 'The counting step shows the feature as off.');
        Assert.AreEqual(Enum::"WHA Setup Step Status"::WHANotStarted, TempSetupStep.Status, 'A feature that is off is a step not started.');
    end;

    [Test]
    procedure TheFoundationStepIsNotStartedWithoutItsRecord()
    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        WarehouseSetup: Record "WHA Warehouse Setup";
        GuidedSetup: Codeunit "WHA Guided Setup";
    begin
        // [GIVEN] No foundation record
        WarehouseSetup.DeleteAll();

        // [WHEN] The hub builds its list
        GuidedSetup.PopulateSteps(TempSetupStep);

        // [THEN] The foundation step is not started
        TempSetupStep.SetRange("Step No.", 10);
        TempSetupStep.FindFirst();
        Assert.AreEqual(Enum::"WHA Setup Step Status"::WHANotStarted, TempSetupStep.Status, 'Without its record the foundation is not set up.');
    end;

    [Test]
    procedure FinishingTheFoundationStepCreatesItsRecord()
    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        WarehouseSetup: Record "WHA Warehouse Setup";
        GuidedSetup: Codeunit "WHA Guided Setup";
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        // [GIVEN] No foundation record, and the hub's foundation step
        WarehouseSetup.DeleteAll();
        GuidedSetup.PopulateSteps(TempSetupStep);
        TempSetupStep.SetRange("Step No.", 10);
        TempSetupStep.FindFirst();

        // [WHEN] The wizard for that step is finished
        GuidedSetup.ApplyWizardChoices(TempSetupStep, true, false, false);

        // [THEN] The foundation record exists
        Assert.IsTrue(SetupLogic.IsComplete(), 'Finishing the foundation step creates the foundation record.');
    end;

    [Test]
    procedure FinishingAFeatureStepAppliesTheChoices()
    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        GuidedSetup: Codeunit "WHA Guided Setup";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        // [GIVEN] Wave management switched off, and the hub's wave step
        FeatureSetup := Enum::"WHA Feature"::WHAWaveManagement;
        FeatureSetup.ApplyChoices(false, false, false);
        GuidedSetup.PopulateSteps(TempSetupStep);
        TempSetupStep.SetRange(Feature, Enum::"WHA Feature"::WHAWaveManagement);
        TempSetupStep.FindFirst();

        // [WHEN] The wizard for that step is finished with the toggle on
        GuidedSetup.ApplyWizardChoices(TempSetupStep, true, false, false);

        // [THEN] Wave management is on
        Assert.IsTrue(FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAWaveManagement), 'Finishing the wizard with the toggle on switches the feature on.');
    end;

    local procedure AssertSeries(ExpectedCode: Code[20]; ActualCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        Assert.AreEqual(ExpectedCode, ActualCode, StrSubstNo(FeatureMsg, ExpectedCode, 'The setup should point at series it.'));
        Assert.IsTrue(NoSeries.Get(ActualCode), StrSubstNo(FeatureMsg, ExpectedCode, 'Series it should exist.'));
        NoSeriesLine.SetRange("Series Code", ActualCode);
        Assert.IsFalse(NoSeriesLine.IsEmpty(), StrSubstNo(FeatureMsg, ExpectedCode, 'Series it should have a line to number from.'));
    end;

    local procedure AppAreaOf(var TempApplicationAreaSetup: Record "Application Area Setup" temporary; Feature: Enum "WHA Feature"): Boolean
    begin
        case Feature of
            Feature::WHAHandlingUnits:
                exit(TempApplicationAreaSetup."WHA Handling Units");
            Feature::WHADirectedWork:
                exit(TempApplicationAreaSetup."WHA Directed Work");
            Feature::WHAIntegration:
                exit(TempApplicationAreaSetup."WHA Integration");
            Feature::WHAMobileDevice:
                exit(TempApplicationAreaSetup."WHA Mobile Device");
            Feature::WHAWaveManagement:
                exit(TempApplicationAreaSetup."WHA Wave Management");
            Feature::WHALabelling:
                exit(TempApplicationAreaSetup."WHA Labelling");
            Feature::WHAPacking:
                exit(TempApplicationAreaSetup."WHA Packing");
            Feature::WHAReplenishment:
                exit(TempApplicationAreaSetup."WHA Replenishment");
            Feature::WHACounting:
                exit(TempApplicationAreaSetup."WHA Counting");
            Feature::WHAQualityHold:
                exit(TempApplicationAreaSetup."WHA Quality Hold");
            Feature::WHALabourManagement:
                exit(TempApplicationAreaSetup."WHA Labour Management");
            Feature::WHASlotting:
                exit(TempApplicationAreaSetup."WHA Slotting");
            Feature::WHADockYard:
                exit(TempApplicationAreaSetup."WHA Dock Yard");
            Feature::WHAAnalytics:
                exit(TempApplicationAreaSetup."WHA Analytics");
        end;
        Error('Feature %1 has no application area in this test.', Feature);
    end;
}
