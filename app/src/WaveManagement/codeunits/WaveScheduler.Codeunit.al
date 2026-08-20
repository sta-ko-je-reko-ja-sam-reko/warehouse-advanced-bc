namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;
using WarehouseAdvanced.Telemetry;

codeunit 50158 "WHA Wave Scheduler"
{
    Access = Public;
    TableNo = "WHA Wave Template";

    var
        FeatureNameTok: Label 'Wave management', Locked = true;
        RunNameTok: Label 'Release waves from templates', Locked = true;

    /// <summary>
    /// Builds a wave from every template marked for the scheduled run. Point a job queue entry at this
    /// codeunit and Business Central decides when it happens; this feature never learns how to schedule,
    /// because the platform already knows and does it better than a setup page would.
    /// </summary>
    /// <param name="Rec">A wave template record whose Location Code filter, if any, limits the run.</param>
    trigger OnRun()
    var
        Telemetry: Codeunit "WHA Telemetry";
        WaveTemplateLogic: Codeunit "WHA Wave Template Logic";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        Handled: Integer;
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        Handled := WaveTemplateLogic.RunScheduled(CopyStr(Rec.GetFilter("Location Code"), 1, MaxStrLen(Rec."Location Code")));
        Telemetry.LogScheduledRun(FeatureNameTok, RunNameTok, Handled);
    end;
}
