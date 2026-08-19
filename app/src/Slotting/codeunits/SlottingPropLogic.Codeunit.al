namespace WarehouseAdvanced.Slotting;

codeunit 50301 "WHA Slotting Prop. Logic" implements "WHA ISlottingProposal"
{
    Access = Public;

    var
        DeleteNotAllowedErr: Label 'Proposal %1 has been answered, so it cannot be deleted. What was suggested and what was decided is the only record of why the stock sits where it sits.', Comment = '%1 = the proposal entry number';

    /// <summary>
    /// Stamps when the proposal was made.
    /// </summary>
    /// <param name="SlottingProposal">The proposal being inserted.</param>
    procedure Trigger_OnInsert(var SlottingProposal: Record "WHA Slotting Proposal")
    begin
        SlottingProposal."Created At" := CurrentDateTime;
    end;

    /// <summary>
    /// Refuses to delete a proposal somebody has already answered.
    /// </summary>
    /// <param name="SlottingProposal">The proposal being deleted.</param>
    procedure Trigger_OnDelete(var SlottingProposal: Record "WHA Slotting Proposal")
    begin
        if SlottingProposal.Status = SlottingProposal.Status::WHAOpen then
            exit;

        Error(DeleteNotAllowedErr, SlottingProposal."Entry No.");
    end;
}
