namespace WarehouseAdvanced.Slotting;

codeunit 50306 "WHA Velocity By Quantity" implements "WHA IVelocityBasis"
{
    Access = Public;

    var
        DescriptionLbl: Label 'How much of the item is picked. This favours the items that move in volume, even if they are fetched rarely.';

    /// <summary>
    /// Ranks an item on the quantity picked. Right where the handling rather than the walking is the
    /// work: a warehouse moving pallets of one line cares about the volume, not the number of trips.
    /// </summary>
    /// <param name="ItemVelocity">The item's movement over the period.</param>
    /// <returns>The quantity picked.</returns>
    procedure Rank(var ItemVelocity: Record "WHA Item Velocity"): Decimal
    begin
        exit(ItemVelocity."Quantity Moved");
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
