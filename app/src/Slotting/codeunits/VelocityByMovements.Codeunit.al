namespace WarehouseAdvanced.Slotting;

codeunit 50305 "WHA Velocity By Movements" implements "WHA IVelocityBasis"
{
    Access = Public;

    var
        DescriptionLbl: Label 'How often the item is picked. One pick is one trip, whatever was taken, so this favours the items people walk to most.';

    /// <summary>
    /// Ranks an item on how many times it was picked. This is the right answer for most warehouses: the
    /// cost of a pick is the walk, and the walk happens once per trip whatever comes back on the truck.
    /// </summary>
    /// <param name="ItemVelocity">The item's movement over the period.</param>
    /// <returns>The number of picks.</returns>
    procedure Rank(var ItemVelocity: Record "WHA Item Velocity"): Decimal
    begin
        exit(ItemVelocity.Movements);
    end;

    /// <summary>
    /// Describes in one line what this basis ranks on.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
