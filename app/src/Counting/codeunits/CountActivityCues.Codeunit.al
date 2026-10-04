namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

codeunit 55508 "WHA Count Activity Cues" implements "WHA IActivityCues"
{
    Access = Public;

    /// <summary>
    /// Adds this feature's counts to what the role centre is waiting for. A feature that is switched off
    /// adds nothing, so its tiles stay at zero rather than counting work nobody can act on.
    /// </summary>
    /// <param name="Results">The result buffer, keyed by cue field number.</param>
    procedure AddCounts(var Results: Dictionary of [Text, Text])
    var
        TempActivitiesCue: Record "WHA Activities Cue";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHACounting) then
            exit;

        Results.Add(Format(TempActivitiesCue.FieldNo("WHA Count Sheets Out")), Format(CountCountSheetsOnTheFloor()));
        Results.Add(Format(TempActivitiesCue.FieldNo("WHA Counts To Approve")), Format(CountCountsWaitingForApproval()));
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
        CountSetup: Record "WHA Count Setup";
        CountSheet: Record "WHA Count Sheet";
        CountSheetLine: Record "WHA Count Sheet Line";
        Waiting: Integer;
    begin
        CountSetup.SetLoadFields("Approve Variances");
        if CountSetup.Get() then
            if not CountSetup."Approve Variances" then
                exit(0);

        CountSheet.SetLoadFields("No.");
        CountSheet.SetRange(Status, CountSheet.Status::WHACounted);
        if not CountSheet.FindSet() then
            exit(0);

        repeat
            CountSheetLine.SetRange("Sheet No.", CountSheet."No.");
            CountSheetLine.SetRange("Out of Tolerance", true);
            CountSheetLine.SetRange(Approved, false);
            if not CountSheetLine.IsEmpty() then
                Waiting += 1;
        until CountSheet.Next() = 0;

        exit(Waiting);
    end;
}
