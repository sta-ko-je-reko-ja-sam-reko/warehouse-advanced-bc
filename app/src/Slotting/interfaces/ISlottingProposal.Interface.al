namespace WarehouseAdvanced.Slotting;

interface "WHA ISlottingProposal"
{
    /// <summary>
    /// Stamps when the proposal was made.
    /// </summary>
    /// <param name="SlottingProposal">The proposal being inserted.</param>
    procedure Trigger_OnInsert(var SlottingProposal: Record "WHA Slotting Proposal");

    /// <summary>
    /// Refuses to delete a proposal somebody has already answered. What was proposed and what was decided
    /// is the only record of why stock sits where it sits.
    /// </summary>
    /// <param name="SlottingProposal">The proposal being deleted.</param>
    procedure Trigger_OnDelete(var SlottingProposal: Record "WHA Slotting Proposal");
}
