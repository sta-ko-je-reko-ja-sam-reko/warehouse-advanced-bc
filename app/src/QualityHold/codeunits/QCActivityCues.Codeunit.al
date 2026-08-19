namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;

codeunit 50560 "WHA QC Activity Cues" implements "WHA IActivityCues"
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
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAQualityHold) then
            exit;

        Results.Add(Format(ActivitiesCue.FieldNo("WHA Goods On Hold")), Format(CountGoodsOnHold()));
        Results.Add(Format(ActivitiesCue.FieldNo("WHA Holds To Decide")), Format(CountHoldsWaitingForADecision()));
    end;


    local procedure CountGoodsOnHold(): Integer
    var
        QualityHold: Record "WHA Quality Hold";
    begin
        QualityHold.SetRange(Status, QualityHold.Status::WHAOnHold);
        exit(QualityHold.Count());
    end;
    local procedure CountHoldsWaitingForADecision(): Integer
    var
        QualityHold: Record "WHA Quality Hold";
    begin
        QualityHold.SetRange(Status, QualityHold.Status::WHAOnHold);
        QualityHold.SetRange(Disposition, QualityHold.Disposition::WHAPending);
        exit(QualityHold.Count());
    end;
}
