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
    begin
        if WarehouseSetup."Handling Unit Nos." = xWarehouseSetup."Handling Unit Nos." then
            exit;

        CheckSeriesExists(WarehouseSetup."Handling Unit Nos.");
    end;

    /// <summary>
    /// Validates a change to the warehouse task number series.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record being validated.</param>
    /// <param name="xWarehouseSetup">The setup record as it was before the change.</param>
    procedure Validate_WarehouseTaskNos(var WarehouseSetup: Record "WHA Warehouse Setup"; xWarehouseSetup: Record "WHA Warehouse Setup")
    begin
        if WarehouseSetup."Warehouse Task Nos." = xWarehouseSetup."Warehouse Task Nos." then
            exit;

        CheckSeriesExists(WarehouseSetup."Warehouse Task Nos.");
    end;

    /// <summary>
    /// Validates a change to the wave number series.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record being validated.</param>
    /// <param name="xWarehouseSetup">The setup record as it was before the change.</param>
    procedure Validate_WaveNos(var WarehouseSetup: Record "WHA Warehouse Setup"; xWarehouseSetup: Record "WHA Warehouse Setup")
    begin
        if WarehouseSetup."Wave Nos." = xWarehouseSetup."Wave Nos." then
            exit;

        CheckSeriesExists(WarehouseSetup."Wave Nos.");
    end;

    /// <summary>
    /// Validates a change to the count sheet number series.
    /// </summary>
    /// <param name="WarehouseSetup">The setup record being validated.</param>
    /// <param name="xWarehouseSetup">The setup record as it was before the change.</param>
    procedure Validate_CountSheetNos(var WarehouseSetup: Record "WHA Warehouse Setup"; xWarehouseSetup: Record "WHA Warehouse Setup")
    begin
        if WarehouseSetup."Count Sheet Nos." = xWarehouseSetup."Count Sheet Nos." then
            exit;

        CheckSeriesExists(WarehouseSetup."Count Sheet Nos.");
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
        WarehouseSetup.SetLoadFields("Handling Unit Nos.", "Warehouse Task Nos.", "Wave Nos.", "Count Sheet Nos.");
        if not WarehouseSetup.Get() then
            exit(false);
        if WarehouseSetup."Handling Unit Nos." = '' then
            exit(false);
        if WarehouseSetup."Warehouse Task Nos." = '' then
            exit(false);
        if WarehouseSetup."Wave Nos." = '' then
            exit(false);
        exit(WarehouseSetup."Count Sheet Nos." <> '');
    end;

    local procedure CheckSeriesExists(SeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        if SeriesCode = '' then
            exit;

        NoSeries.SetLoadFields(Code);
        if not NoSeries.Get(SeriesCode) then
            Error(NoSeriesNotFoundErr, SeriesCode);
    end;
}
