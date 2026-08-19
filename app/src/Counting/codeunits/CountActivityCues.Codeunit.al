namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

codeunit 50508 "WHA Count Activity Cues" implements "WHA IActivityCues"
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
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHACounting) then
            exit;

        Results.Add(Format(ActivitiesCue.FieldNo("WHA Count Sheets Out")), Format(CountCountSheetsOnTheFloor()));
        Results.Add(Format(ActivitiesCue.FieldNo("WHA Counts To Approve")), Format(CountCountsWaitingForApproval()));
    end;


    local procedure CountCountSheetsOnTheFloor(): Integer
    var
        CountSheet: Record "WHA Count Sheet";
    begin
        CountSheet.SetRange(Status, CountSheet.Status::WHACounting);
        exit(CountSheet.Count());
    end;
    local procedure CountCountsWaitingForApproval(): Integer
    var
        CountSheet: Record "WHA Count Sheet";
    begin
        CountSheet.SetRange(Status, CountSheet.Status::WHACounted);
        exit(CountSheet.Count());
    end;
}
