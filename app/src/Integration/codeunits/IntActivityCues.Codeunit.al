namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

codeunit 50663 "WHA Int Activity Cues" implements "WHA IActivityCues"
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
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAIntegration) then
            exit;

        Results.Add(Format(ActivitiesCue.FieldNo("WHA Messages Waiting")), Format(CountMessagesWaiting()));
        Results.Add(Format(ActivitiesCue.FieldNo("WHA Messages Failed")), Format(CountMessagesThatFailed()));
    end;


    local procedure CountMessagesWaiting(): Integer
    var
        IntegrationMessage: Record "WHA Integration Message";
    begin
        IntegrationMessage.SetRange(Status, IntegrationMessage.Status::WHANew);
        exit(IntegrationMessage.Count());
    end;
    local procedure CountMessagesThatFailed(): Integer
    var
        IntegrationMessage: Record "WHA Integration Message";
    begin
        IntegrationMessage.SetRange(Status, IntegrationMessage.Status::WHAFailed);
        exit(IntegrationMessage.Count());
    end;
}
