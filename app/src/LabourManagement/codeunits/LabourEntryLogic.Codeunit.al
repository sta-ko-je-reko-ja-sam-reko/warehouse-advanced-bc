namespace WarehouseAdvanced.LabourManagement;

codeunit 50351 "WHA Labour Entry Logic" implements "WHA ILabourEntry"
{
    Access = Public;

    var
        NegativeMinutesErr: Label 'Time cannot be negative.';

    /// <summary>
    /// Fills in the date and the person when they were not given, and classifies time with no job
    /// against it as time off the jobs.
    /// </summary>
    /// <param name="LabourEntry">The entry being inserted.</param>
    procedure Trigger_OnInsert(var LabourEntry: Record "WHA Labour Entry")
    begin
        if LabourEntry."Task No." = '' then
            LabourEntry."Entry Type" := LabourEntry."Entry Type"::WHAIndirect;

        if LabourEntry."User ID" = '' then
            LabourEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(LabourEntry."User ID"));

        if LabourEntry."Posting Date" = 0D then
            LabourEntry."Posting Date" := PostingDateFor(LabourEntry);

        if (LabourEntry."Actual Minutes" = 0) and (LabourEntry."Started At" <> 0DT) and (LabourEntry."Ended At" <> 0DT) then
            LabourEntry."Actual Minutes" := MinutesBetween(LabourEntry."Started At", LabourEntry."Ended At");
    end;

    /// <summary>
    /// Refuses negative time, and works out the performance again when the minutes are corrected by hand.
    /// </summary>
    /// <param name="LabourEntry">The entry being validated.</param>
    /// <param name="xLabourEntry">The entry as it was before the change.</param>
    procedure Validate_ActualMinutes(var LabourEntry: Record "WHA Labour Entry"; xLabourEntry: Record "WHA Labour Entry")
    begin
        if LabourEntry."Actual Minutes" < 0 then
            Error(NegativeMinutesErr);
        if LabourEntry."Actual Minutes" = xLabourEntry."Actual Minutes" then
            exit;

        LabourEntry."Performance Percent" := PerformanceOf(LabourEntry);
    end;

    /// <summary>
    /// Works out the expected time as a percentage of the actual time. A hundred is exactly to standard,
    /// and more than a hundred is faster than standard.
    /// </summary>
    /// <param name="LabourEntry">The entry to measure.</param>
    /// <returns>The performance percentage, or zero where nothing measured the work.</returns>
    procedure PerformanceOf(var LabourEntry: Record "WHA Labour Entry"): Decimal
    begin
        if not LabourEntry."Measured Against Standard" then
            exit(0);
        if LabourEntry."Actual Minutes" <= 0 then
            exit(0);

        exit(Round(LabourEntry."Expected Minutes" / LabourEntry."Actual Minutes" * 100, 0.01));
    end;

    /// <summary>
    /// Answers how many minutes lie between two moments, to two decimal places.
    /// </summary>
    /// <param name="StartedAt">When it started.</param>
    /// <param name="EndedAt">When it ended.</param>
    /// <returns>The number of minutes, or zero when the pair makes no sense.</returns>
    procedure MinutesBetween(StartedAt: DateTime; EndedAt: DateTime): Decimal
    begin
        if (StartedAt = 0DT) or (EndedAt = 0DT) then
            exit(0);
        if EndedAt <= StartedAt then
            exit(0);

        exit(Round((EndedAt - StartedAt) / 60000, 0.01));
    end;

    local procedure PostingDateFor(var LabourEntry: Record "WHA Labour Entry"): Date
    begin
        if LabourEntry."Ended At" <> 0DT then
            exit(DT2Date(LabourEntry."Ended At"));
        exit(WorkDate());
    end;
}
