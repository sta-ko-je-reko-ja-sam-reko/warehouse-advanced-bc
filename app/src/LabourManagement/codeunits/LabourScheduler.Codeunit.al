namespace WarehouseAdvanced.LabourManagement;

using WarehouseAdvanced.Core;

codeunit 50358 "WHA Labour Scheduler"
{
    Access = Public;
    TableNo = "WHA Labour Entry";

    /// <summary>
    /// Turns finished warehouse work into measured time. Point a job queue entry at this codeunit and
    /// Business Central decides when it happens; this feature never learns how to schedule, because the
    /// platform already knows and does it better than a setup page would.
    /// </summary>
    /// <param name="Rec">A labour entry record whose Location Code filter, if any, limits the run to one site.</param>
    /// <remarks>
    /// The run reads the window named by <c>Look back over</c> in the labour setup and skips the jobs in
    /// it that already have an entry. It used to read every job the warehouse had ever finished, which was
    /// correct and got slower for ever; the window is what stops that, and a warehouse that would rather
    /// pay the cost can set it to zero and have the old behaviour back.
    ///
    /// The window has to be longer than the gap between runs. A daily entry with a window of one day has
    /// no margin for the day the job queue was down: work finished in the gap falls out of every run and
    /// is never measured. That is the reason the default is a month rather than a week.
    /// </remarks>
    trigger OnRun()
    var
        LabourMgt: Codeunit "WHA Labour Mgt.";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHALabourManagement);
        LabourMgt.Generate(CopyStr(Rec.GetFilter("Location Code"), 1, MaxStrLen(Rec."Location Code")), LookBackFrom(), 0D);
    end;

    local procedure LookBackFrom(): Date
    var
        Setup: Record "WHA Labour Setup";
        DaysTok: Label '<-%1D>', Locked = true, Comment = '%1 = the number of days to look back';
    begin
        Setup.SetLoadFields("Look Back Days");
        if not Setup.Get() then
            exit(0D);
        if Setup."Look Back Days" <= 0 then
            exit(0D);

        exit(CalcDate(StrSubstNo(DaysTok, Setup."Look Back Days"), WorkDate()));
    end;
}
