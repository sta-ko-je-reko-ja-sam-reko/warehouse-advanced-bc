namespace WarehouseAdvanced.HandlingUnit;

using WarehouseAdvanced.Core;

codeunit 50051 "WHA HU Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Handling units';
        StepDescriptionLbl: Label 'Track pallets and containers as numbered units, so a whole unit can be moved, nested inside another, and labelled with an SSCC.';

    /// <summary>
    /// Adds the handling unit step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 20;
        TempSetupStep.Feature := TempSetupStep.Feature::WHAHandlingUnits;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Handling Unit Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the handling unit setup record.
    /// </summary>
    /// <returns>True when handling units are switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Handling Unit Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for handling units. Never restarts the session; the setup hub
    /// owns the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether handling units should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. The handling unit number series belongs to the foundation step.</param>
    /// <param name="ImportDemoData">Whether to load sample handling units.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Handling Unit Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleUnits();
    end;

    /// <summary>
    /// Ensures the single handling unit setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Handling Unit Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Allow Nesting" := true;
        Setup.Insert(true);
    end;

    local procedure ImportSampleUnits()
    begin
    end;
}
