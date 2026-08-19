namespace WarehouseAdvanced.Replenishment;

interface "WHA IReplMethod"
{
    /// <summary>
    /// Answers how much of the rule's item is in its pick bin right now. A method reads; it never
    /// decides whether that is too little, and it never raises work.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule whose bin is being measured.</param>
    /// <returns>The quantity the method believes is in the bin.</returns>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"): Decimal;

    /// <summary>
    /// Describes in one line where this method gets its number from, so the person writing a rule knows
    /// what it will be measuring before it measures anything.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
