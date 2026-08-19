namespace WarehouseAdvanced.Replenishment;

interface "WHA IReplenishment"
{
    /// <summary>
    /// Applies the defaults a new replenishment rule needs.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule being inserted.</param>
    procedure Trigger_OnInsert(var ReplenishmentRule: Record "WHA Replenishment Rule");

    /// <summary>
    /// Clears the variant and unit of measure when the item changes, then copies the base unit of
    /// measure from the item.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule being validated.</param>
    /// <param name="xReplenishmentRule">The rule as it was before the change.</param>
    procedure Validate_ItemNo(var ReplenishmentRule: Record "WHA Replenishment Rule"; xReplenishmentRule: Record "WHA Replenishment Rule");

    /// <summary>
    /// Refuses a minimum above the maximum, which would ask for a bin to be filled past the point it is
    /// allowed to hold.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule being validated.</param>
    /// <param name="xReplenishmentRule">The rule as it was before the change.</param>
    procedure Validate_MinimumQuantity(var ReplenishmentRule: Record "WHA Replenishment Rule"; xReplenishmentRule: Record "WHA Replenishment Rule");

    /// <summary>
    /// Refuses a maximum below the minimum.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule being validated.</param>
    /// <param name="xReplenishmentRule">The rule as it was before the change.</param>
    procedure Validate_MaximumQuantity(var ReplenishmentRule: Record "WHA Replenishment Rule"; xReplenishmentRule: Record "WHA Replenishment Rule");
}
