namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

codeunit 50308 "WHA Slot Activity Cues" implements "WHA IActivityCues"
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
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHASlotting) then
            exit;

        Results.Add(Format(ActivitiesCue.FieldNo("WHA Slotting Proposals Open")), Format(CountSlottingProposalsWaiting()));
    end;


    local procedure CountSlottingProposalsWaiting(): Integer
    var
        SlottingProposal: Record "WHA Slotting Proposal";
    begin
        SlottingProposal.SetRange(Status, SlottingProposal.Status::WHAOpen);
        exit(SlottingProposal.Count());
    end;
}
