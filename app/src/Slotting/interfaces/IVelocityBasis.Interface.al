namespace WarehouseAdvanced.Slotting;

interface "WHA IVelocityBasis"
{
    /// <summary>
    /// Answers the number an item is ranked on. A basis turns a count of trips and a quantity moved into
    /// the one figure the classification sorts by; it never decides the class, so the Pareto split is the
    /// same whichever basis a warehouse chooses.
    /// </summary>
    /// <param name="ItemVelocity">The item's movement over the period.</param>
    /// <returns>The figure to rank the item on.</returns>
    procedure Rank(var ItemVelocity: Record "WHA Item Velocity"): Decimal;

    /// <summary>
    /// Describes in one line what this basis ranks on, because the two answers differ and the difference
    /// decides which items end up in the best bins.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
