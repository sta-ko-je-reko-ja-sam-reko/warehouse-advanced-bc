namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;
using WarehouseAdvanced.Telemetry;

codeunit 50260 "WHA Repl. Scheduler"
{
    Access = Public;
    TableNo = "WHA Replenishment Rule";

    var
        FeatureNameTok: Label 'Replenishment', Locked = true;
        RunNameTok: Label 'Top up pick bins', Locked = true;

    /// <summary>
    /// Measures every rule and raises the work the pick faces need. Point a job queue entry at this
    /// codeunit and Business Central decides when it happens; this feature never learns how to schedule,
    /// because the platform already knows and does it better than a setup page would.
    /// </summary>
    /// <param name="Rec">A replenishment rule record whose Location Code filter, if any, limits the run.</param>
    trigger OnRun()
    var
        Telemetry: Codeunit "WHA Telemetry";
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        Handled: Integer;
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAReplenishment);
        Handled := ReplenishmentMgt.Run(CopyStr(Rec.GetFilter("Location Code"), 1, MaxStrLen(Rec."Location Code")));
        Telemetry.LogScheduledRun(FeatureNameTok, RunNameTok, Handled);
    end;
}
