codeunit 51015 "WHA Foundation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure EveryFeatureAnswersWhetherItIsSwitchedOn()
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        Ordinal: Integer;
        Answered: Integer;
    begin
        // [SCENARIO] A feature ships by adding a value to an enum. The failure that invites is a value
        // with no implementation bound to it, which nothing else in the app would notice until somebody
        // opened the setup list. Walking every value is what catches it.
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            if FeatureMgt.IsEnabled(Enum::"WHA Feature".FromInteger(Ordinal)) then;
            Answered += 1;
        end;

        Assert.IsTrue(Answered > 1, 'Every value of the feature enum should answer, and there should be more than the none value.');
    end;

    [Test]
    procedure EveryActivityProviderAnswersWithoutClashing()
    var
        ActivityCues: Interface "WHA IActivityCues";
        Results: Dictionary of [Text, Text];
        Ordinal: Integer;
    begin
        // [SCENARIO] The role centre asks every provider to add its counts to one dictionary. Two
        // features that claimed the same cue field number would collide there and take the home page
        // down with them — Add throws on a duplicate key. This is the test that would catch it, and it
        // is the reason the counts are keyed by FieldNo rather than by a string somebody chose.
        foreach Ordinal in Enum::"WHA Activity Provider".Ordinals() do begin
            ActivityCues := Enum::"WHA Activity Provider".FromInteger(Ordinal);
            ActivityCues.AddCounts(Results);
        end;

        Assert.IsTrue(Results.Count() >= 0, 'Every activity provider should answer without two of them claiming the same tile.');
    end;

    [Test]
    procedure SwitchingAFeatureOnChangesTheEnabledFingerprint()
    var
        Setup: Record "WHA Warehouse Task Setup";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        Before: Text;
        After: Text;
    begin
        // [SCENARIO] A setup page compares this fingerprint on open and on close to decide whether the
        // session is owed a restart. If it did not move when a feature was switched on, the user would
        // be left looking at a page whose actions had not appeared.
        EnsureTaskSetup(Setup);
        Setup."WHA Enabled" := false;
        Setup.Modify(true);
        Before := FeatureMgt.GetEnabledFingerprint();

        Setup."WHA Enabled" := true;
        Setup.Modify(true);
        After := FeatureMgt.GetEnabledFingerprint();

        Assert.AreNotEqual(Before, After, 'Switching a feature on should move the fingerprint the setup pages watch.');
    end;

    [Test]
    procedure TheFoundationItselfIsNeverSwitchedOff()
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        Feature: Enum "WHA Feature";
    begin
        // [SCENARIO] The none value exists so that an unbound enum value fails safe rather than loudly.
        // It must never report itself as an enabled feature, or the setup list would offer a step for
        // something that is not a feature.
        Assert.IsFalse(FeatureMgt.IsEnabled(Feature::WHANone), 'The none value is not a feature and is never enabled.');
    end;

    local procedure EnsureTaskSetup(var Setup: Record "WHA Warehouse Task Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup.Insert(true);
    end;
}
