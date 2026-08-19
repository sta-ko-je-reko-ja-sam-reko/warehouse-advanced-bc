namespace WarehouseAdvanced.HandlingUnit;

interface "WHA IHandlingUnitLine"
{
    /// <summary>
    /// Assigns the next line number and refuses the insert when the handling unit is no longer open.
    /// </summary>
    /// <param name="HandlingUnitLine">The line being inserted.</param>
    procedure Trigger_OnInsert(var HandlingUnitLine: Record "WHA Handling Unit Line");

    /// <summary>
    /// Copies the description and base unit of measure from the item, and clears the variant when the
    /// item changes so a variant of the previous item cannot be kept.
    /// </summary>
    /// <param name="HandlingUnitLine">The line being validated.</param>
    /// <param name="xHandlingUnitLine">The line as it was before the change.</param>
    procedure Validate_ItemNo(var HandlingUnitLine: Record "WHA Handling Unit Line"; xHandlingUnitLine: Record "WHA Handling Unit Line");

    /// <summary>
    /// Rejects a negative quantity, and rejects a quantity other than one when the line carries a
    /// serial number.
    /// </summary>
    /// <param name="HandlingUnitLine">The line being validated.</param>
    /// <param name="xHandlingUnitLine">The line as it was before the change.</param>
    procedure Validate_Quantity(var HandlingUnitLine: Record "WHA Handling Unit Line"; xHandlingUnitLine: Record "WHA Handling Unit Line");

    /// <summary>
    /// Returns the next free line number for a handling unit.
    /// </summary>
    /// <param name="HandlingUnitNo">The handling unit to number a line for.</param>
    /// <returns>The next line number, in steps of ten thousand.</returns>
    procedure GetNextLineNo(HandlingUnitNo: Code[20]): Integer;
}
