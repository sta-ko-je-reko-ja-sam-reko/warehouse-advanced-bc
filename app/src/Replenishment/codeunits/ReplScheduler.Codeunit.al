namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

codeunit 50260 "WHA Repl. Scheduler"
{
    Access = Public;
    TableNo = "WHA Replenishment Rule";

    /// <summary>
    /// Measures every rule and raises the work the pick faces need. Point a job queue entry at this
    /// codeunit and Business Central decides when it happens; this feature never learns how to schedule,
    /// because the platform already knows and does it better than a setup page would.
    /// </summary>
    /// <param name="Rec">A replenishment rule record whose Location Code filter, if any, limits the run.</param>
    trigger OnRun()
    var
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAReplenishment);
        ReplenishmentMgt.Run(CopyStr(Rec.GetFilter("Location Code"), 1, MaxStrLen(Rec."Location Code")));
    end;
}
