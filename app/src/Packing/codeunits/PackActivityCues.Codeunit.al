namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

codeunit 50404 "WHA Pack Activity Cues" implements "WHA IActivityCues"
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
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAPacking) then
            exit;

        Results.Add(Format(ActivitiesCue.FieldNo("WHA Cartons Being Packed")), Format(CountCartonsBeingPacked()));
    end;


    local procedure CountCartonsBeingPacked(): Integer
    var
        PackSession: Record "WHA Pack Session";
    begin
        PackSession.SetRange(Status, PackSession.Status::WHAPacking);
        exit(PackSession.Count());
    end;
}
