namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

interface "WHA IHoldDisposition"
{
    /// <summary>
    /// Decides what becomes of the goods when a hold is lifted. A disposition owns exactly one thing —
    /// the state the handling unit is left in — and never touches the hold record itself, so a new
    /// disposition cannot get the audit trail wrong.
    /// </summary>
    /// <param name="QualityHold">The hold being released.</param>
    /// <param name="HandlingUnit">The handling unit the hold was placed on.</param>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit");

    /// <summary>
    /// Describes in one line what this decision does to the goods, so whoever is about to make it can see
    /// what they are agreeing to before they agree to it.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;

    /// <summary>
    /// Answers whether this decision puts the goods back into use. The hold list uses it to show what is
    /// waiting to come back and what is not.
    /// </summary>
    /// <returns>True when releasing with this decision makes the unit available again.</returns>
    procedure ReturnsToUse(): Boolean;

    /// <summary>
    /// Answers whether this decision takes the goods out of stock for good, and so whether releasing the
    /// hold should write them off. The hold manager asks; the disposition never posts anything itself,
    /// because who wrote what off and under which document is part of the audit trail the hold owns.
    /// </summary>
    /// <returns>True when the goods are gone and the ledger should say so.</returns>
    procedure WritesOffStock(): Boolean;
}
