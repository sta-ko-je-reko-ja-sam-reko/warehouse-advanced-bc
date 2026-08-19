namespace WarehouseAdvanced.Replenishment;

using Microsoft.Inventory.Item;

codeunit 50263 "WHA Repl. Unit Convert"
{
    Access = Public;

    /// <summary>
    /// Turns a quantity expressed in one unit of measure into the base unit the item is counted in.
    /// </summary>
    /// <param name="ItemNo">The item the quantity belongs to.</param>
    /// <param name="UnitOfMeasureCode">The unit the quantity is expressed in. Blank means it is already base.</param>
    /// <param name="Quantity">The quantity to convert.</param>
    /// <returns>The quantity in the item's base unit.</returns>
    procedure ToBase(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal): Decimal
    begin
        exit(Quantity * QtyPerUnit(ItemNo, UnitOfMeasureCode));
    end;

    /// <summary>
    /// Turns a base quantity into the unit a replenishment rule is written in, so a minimum in pallets is
    /// compared with a measurement in pallets.
    /// </summary>
    /// <param name="ItemNo">The item the quantity belongs to.</param>
    /// <param name="UnitOfMeasureCode">The unit to express it in. Blank means leave it in base.</param>
    /// <param name="BaseQuantity">The quantity in the item's base unit.</param>
    /// <returns>The quantity in the named unit.</returns>
    procedure FromBase(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; BaseQuantity: Decimal): Decimal
    var
        PerUnit: Decimal;
    begin
        PerUnit := QtyPerUnit(ItemNo, UnitOfMeasureCode);
        if PerUnit = 0 then
            exit(BaseQuantity);

        exit(BaseQuantity / PerUnit);
    end;

    /// <summary>
    /// Answers how many base units one of the named unit holds.
    /// </summary>
    /// <param name="ItemNo">The item.</param>
    /// <param name="UnitOfMeasureCode">The unit. Blank is base.</param>
    /// <returns>The conversion factor, and one where none is on record.</returns>
    /// <remarks>
    /// A unit of measure that is not set up for the item answers one rather than raising. A replenishment
    /// run is scheduled and unattended: an error here would stop every other rule in the run over one
    /// item's missing setup, and a rule measured in the wrong unit is visible on the rule card where a
    /// run that never happened is not.
    /// </remarks>
    procedure QtyPerUnit(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]): Decimal
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if UnitOfMeasureCode = '' then
            exit(1);

        ItemUnitOfMeasure.SetLoadFields("Qty. per Unit of Measure");
        if not ItemUnitOfMeasure.Get(ItemNo, UnitOfMeasureCode) then
            exit(1);
        if ItemUnitOfMeasure."Qty. per Unit of Measure" <= 0 then
            exit(1);

        exit(ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;
}
