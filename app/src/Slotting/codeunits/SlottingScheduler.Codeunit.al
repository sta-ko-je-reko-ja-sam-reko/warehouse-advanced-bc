namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

codeunit 50307 "WHA Slotting Scheduler"
{
    Access = Public;
    TableNo = "WHA Item Velocity";

    var
        LocationFilterMissingErr: Label 'Set a location code filter on the job queue entry before scheduling the slotting analysis. Analysing a location replaces everything known about it, so a run that swept every location would wipe the classes of any site that simply had a quiet period.';

    /// <summary>
    /// Re-measures how fast every item moves at a location and proposes the moves that follow from it.
    /// Point a job queue entry at this codeunit and Business Central decides when it happens; this
    /// feature never learns how to schedule, because the platform already knows and does it better than a
    /// setup page would.
    /// </summary>
    /// <param name="Rec">An item velocity record whose Location Code filter names the site to analyse. Required.</param>
    trigger OnRun()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        LocationCode: Code[10];
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHASlotting);

        LocationCode := CopyStr(Rec.GetFilter("Location Code"), 1, MaxStrLen(Rec."Location Code"));
        if LocationCode = '' then
            Error(LocationFilterMissingErr);

        if SlottingMgt.Analyse(LocationCode, 0D, 0D) = 0 then
            exit;

        SlottingMgt.Propose(LocationCode);
    end;
}
