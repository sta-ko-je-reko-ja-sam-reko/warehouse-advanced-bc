namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

codeunit 50159 "WHA Wave Activity Cues" implements "WHA IActivityCues"
{
    Access = Public;

    /// <summary>
    /// Adds this feature's counts to what the role centre is waiting for. A feature that is switched off
    /// adds nothing, so its tiles stay at zero rather than counting work nobody can act on.
    /// </summary>
    /// <param name="Results">The result buffer, keyed by cue field number.</param>
    procedure AddCounts(var Results: Dictionary of [Text, Text])
    var
        ActivitiesCue: Record "WHA Activities Cue";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAWaveManagement) then
            exit;

        Results.Add(Format(ActivitiesCue.FieldNo("WHA Waves Open")), Format(CountWavesBeingBuilt()));
        Results.Add(Format(ActivitiesCue.FieldNo("WHA Waves On Floor")), Format(CountWavesOnTheFloor()));
    end;


    local procedure CountWavesBeingBuilt(): Integer
    var
        Wave: Record "WHA Wave";
    begin
        Wave.SetRange(Status, Wave.Status::WHAOpen);
        exit(Wave.Count());
    end;
    local procedure CountWavesOnTheFloor(): Integer
    var
        Wave: Record "WHA Wave";
    begin
        Wave.SetRange(Status, Wave.Status::WHAReleased);
        exit(Wave.Count());
    end;
}
