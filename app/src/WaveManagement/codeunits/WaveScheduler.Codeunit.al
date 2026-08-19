namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

codeunit 50158 "WHA Wave Scheduler"
{
    Access = Public;
    TableNo = "WHA Wave Template";

    /// <summary>
    /// Builds a wave from every template marked for the scheduled run. Point a job queue entry at this
    /// codeunit and Business Central decides when it happens; this feature never learns how to schedule,
    /// because the platform already knows and does it better than a setup page would.
    /// </summary>
    /// <param name="Rec">A wave template record whose Location Code filter, if any, limits the run.</param>
    trigger OnRun()
    var
        WaveTemplateLogic: Codeunit "WHA Wave Template Logic";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        WaveTemplateLogic.RunScheduled(CopyStr(Rec.GetFilter("Location Code"), 1, MaxStrLen(Rec."Location Code")));
    end;
}
