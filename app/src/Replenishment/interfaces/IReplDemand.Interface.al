namespace WarehouseAdvanced.Replenishment;

interface "WHA IReplDemand"
{
    /// <summary>
    /// Answers how much of the rule's item is already spoken for out of its pick bin — work that has been
    /// planned but not yet walked. A method reads; it never decides whether the bin is too low and never
    /// raises work, exactly as the measurement methods do not.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule whose bin is being weighed up.</param>
    /// <param name="WaveNo">The wave being planned for, when the caller is planning for one. Implementations that do not care about waves ignore it.</param>
    /// <returns>The quantity already promised out of the bin.</returns>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"; WaveNo: Code[20]): Decimal;

    /// <summary>
    /// Describes in one line what this way of counting demand looks at, so whoever chooses it in setup
    /// can see what a run will take into account before it starts raising work.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
