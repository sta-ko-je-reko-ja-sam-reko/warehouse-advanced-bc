namespace WarehouseAdvanced.Core;

using Microsoft.Foundation.NoSeries;

codeunit 50000 "WHA Warehouse Setup Logic" implements "WHA IWarehouseSetup"
{
    Access = Public;

    var
        NoSeriesNotFoundErr: Label 'The number series %1 does not exist.', Comment = '%1 = the number series code that was entered';

    /// <summary>
    /// Validates a change to the handling unit number series.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record being validated.</param>
    /// <param name="xWarehouseSetup">The setup record as it was before the change.</param>
    procedure Validate_HandlingUnitNos(var WarehouseSetup: Record "WHA Warehouse Setup"; xWarehouseSetup: Record "WHA Warehouse Setup")
    var
        NoSeries: Record "No. Series";
    begin
        if WarehouseSetup."Handling Unit Nos." = xWarehouseSetup."Handling Unit Nos." then
            exit;
        if WarehouseSetup."Handling Unit Nos." = '' then
            exit;

        NoSeries.SetLoadFields(Code);
        if not NoSeries.Get(WarehouseSetup."Handling Unit Nos.") then
            Error(NoSeriesNotFoundErr, WarehouseSetup."Handling Unit Nos.");
    end;

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
    /// <returns>True when every prerequisite the guided setup checks for is populated.</returns>
    procedure IsComplete(): Boolean
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
    begin
        WarehouseSetup.SetLoadFields("Handling Unit Nos.");
        if not WarehouseSetup.Get() then
            exit(false);
        exit(WarehouseSetup."Handling Unit Nos." <> '');
    end;
}
