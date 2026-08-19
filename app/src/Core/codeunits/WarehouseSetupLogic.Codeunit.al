namespace WarehouseAdvanced.Core;

codeunit 50000 "WHA Warehouse Setup Logic" implements "WHA IWarehouseSetup"
{
    Access = Public;

    /// <summary>
    /// Ensures the single setup record exists, creating it if it does not.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record to materialise.</param>
    procedure EnsureExists(var WarehouseSetup: Record "WHA Warehouse Setup")
    begin
        WarehouseSetup.Reset();
        if WarehouseSetup.Get() then
            exit;

        WarehouseSetup.Init();
        WarehouseSetup.Insert(true);
    end;

    /// <summary>
    /// Determines whether the foundation setup has been completed.
    /// </summary>
    /// <returns>True when the foundation setup record is present.</returns>
    procedure IsComplete(): Boolean
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
    begin
        exit(WarehouseSetup.Get());
    end;
}
