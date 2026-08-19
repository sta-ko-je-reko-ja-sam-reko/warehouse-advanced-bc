namespace WarehouseAdvanced.Core;

interface "WHA IWarehouseSetup"
{
    /// <summary>
    /// Ensures the single setup record exists, creating it if it does not.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record to materialise.</param>
    procedure EnsureExists(var WarehouseSetup: Record "WHA Warehouse Setup");

    /// <summary>
    /// Determines whether the foundation setup has been completed. The foundation holds no feature
    /// settings - each feature owns its own, numbering included - so the only thing it can be asked is
    /// whether the record every feature builds on exists.
    /// </summary>
    /// <returns>True when the foundation setup record is present.</returns>
    procedure IsComplete(): Boolean;
}
