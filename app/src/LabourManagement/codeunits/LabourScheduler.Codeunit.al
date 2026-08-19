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
    /// The run is bounded by nothing but the work itself: it reads every completed job and skips the ones
    /// that already have an entry. That is safe to repeat, and it costs more each time the history grows.
    /// A period to look back over would bound it, and there is nowhere to put one until somebody asks.
    /// </remarks>
    trigger OnRun()
    var
        LabourMgt: Codeunit "WHA Labour Mgt.";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHALabourManagement);
        LabourMgt.Generate(CopyStr(Rec.GetFilter("Location Code"), 1, MaxStrLen(Rec."Location Code")), 0D, 0D);
    end;
}
