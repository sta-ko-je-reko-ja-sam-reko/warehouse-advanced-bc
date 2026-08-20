namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

interface "WHA IHoldStockPolicy"
{
    /// <summary>
    /// Stops Business Central handing the held goods out, in whatever way this policy stops it. An
    /// implementation that does nothing is a complete implementation.
    /// </summary>
    /// <param name="QualityHold">The hold being placed.</param>
    /// <param name="HandlingUnit">The unit being held.</param>
    /// <returns>How many things in Business Central were blocked.</returns>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer;

    /// <summary>
    /// Lets the goods go again, undoing exactly what `Apply` did and nothing else.
    /// </summary>
    /// <param name="QualityHold">The hold being closed.</param>
    /// <param name="HandlingUnit">The unit that was held.</param>
    /// <returns>How many things in Business Central were released.</returns>
    procedure Lift(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer;

    /// <summary>
    /// Describes in one line what this policy does to Business Central, so whoever chooses it in setup
    /// can see how far the hold reaches before the first pallet is stopped.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
