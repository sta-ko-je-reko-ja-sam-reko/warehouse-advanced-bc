namespace WarehouseAdvanced.Core;

interface "WHA IWarehouseSetup"
{
    /// <summary>
    /// Validates a change to the handling unit number series.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record being validated.</param>
    /// <param name="xWarehouseSetup">The setup record as it was before the change.</param>
    procedure Validate_HandlingUnitNos(var WarehouseSetup: Record "WHA Warehouse Setup"; xWarehouseSetup: Record "WHA Warehouse Setup");

    /// <summary>
    /// Validates a change to the warehouse task number series.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record being validated.</param>
    /// <param name="xWarehouseSetup">The setup record as it was before the change.</param>
    procedure Validate_WarehouseTaskNos(var WarehouseSetup: Record "WHA Warehouse Setup"; xWarehouseSetup: Record "WHA Warehouse Setup");

    /// <summary>
    /// Ensures the single setup record exists, creating it if it does not.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record to materialise.</param>
    procedure EnsureExists(var WarehouseSetup: Record "WHA Warehouse Setup");

    /// <summary>
    /// Determines whether the foundation setup has been completed.
    /// </summary>
    /// <returns>True when every prerequisite the guided setup checks for is populated.</returns>
    procedure IsComplete(): Boolean;
}
