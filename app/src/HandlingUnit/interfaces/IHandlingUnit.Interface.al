namespace WarehouseAdvanced.HandlingUnit;

interface "WHA IHandlingUnit"
{
    /// <summary>
    /// Assigns the number series value and any defaults a new handling unit needs.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit being inserted.</param>
    procedure Trigger_OnInsert(var HandlingUnit: Record "WHA Handling Unit");

    /// <summary>
    /// Refuses the delete when the handling unit still holds nested units.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit being deleted.</param>
    procedure Trigger_OnDelete(var HandlingUnit: Record "WHA Handling Unit");

    /// <summary>
    /// Clears the bin when the location changes, so a bin from the previous location cannot be kept.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit being validated.</param>
    /// <param name="xHandlingUnit">The handling unit as it was before the change.</param>
    procedure Validate_LocationCode(var HandlingUnit: Record "WHA Handling Unit"; xHandlingUnit: Record "WHA Handling Unit");

    /// <summary>
    /// Rejects a parent that would nest a unit inside itself, form a cycle, or exceed the configured
    /// nesting depth.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit being validated.</param>
    /// <param name="xHandlingUnit">The handling unit as it was before the change.</param>
    procedure Validate_ParentNo(var HandlingUnit: Record "WHA Handling Unit"; xHandlingUnit: Record "WHA Handling Unit");

    /// <summary>
    /// Calculates how deep a handling unit sits in the nesting hierarchy.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit to measure.</param>
    /// <returns>Zero for a unit with no parent, one for a unit inside a top-level unit, and so on.</returns>
    procedure GetNestingDepth(var HandlingUnit: Record "WHA Handling Unit"): Integer;
}
