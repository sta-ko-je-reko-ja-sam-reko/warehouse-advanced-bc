namespace WarehouseAdvanced.HandlingUnit;

using WarehouseAdvanced.Core;

codeunit 50051 "WHA HU Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Handling units';
        StepDescriptionLbl: Label 'Track pallets and containers as numbered units, so a whole unit can be moved, nested inside another, and labelled with an SSCC.';
        NoSeriesCodeTok: Label 'WHA-HU', Locked = true;
        NoSeriesDescLbl: Label 'Warehouse advanced handling units';
        StartingNoTok: Label 'HU000001', Locked = true;
        EndingNoTok: Label 'HU999999', Locked = true;
        McpConfigNameTok: Label 'Warehouse Advanced - Handling Units', Locked = true;
        McpConfigDescLbl: Label 'Handling unit tools. Read the Warehouse Advanced Handling Units agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Handling Units', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample handling units. Read the Warehouse Advanced Demo Handling Units agent instructions before use.';

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
        TempSetupStep."Has No. Series" := true;
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
    /// <param name="CreateNoSeries">Whether to create the number series that numbers handling units, and assign it to this feature's own setup.</param>
    /// <param name="ImportDemoData">Whether to load sample handling units.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Handling Unit Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if CreateNoSeries then
            EnsureNoSeries(Setup);

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

    /// <summary>
    /// Creates or refreshes the handling unit MCP configuration and its API tool.
    /// </summary>
    procedure RegisterMcpConfiguration()
    begin
        RegisterFunctionalConfiguration();
        RegisterDemoConfiguration();
    end;

    local procedure EnsureNoSeries(var Setup: Record "WHA Handling Unit Setup")
    var
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
    begin
        if Setup."Handling Unit Nos." <> '' then
            exit;

        Setup.Validate("Handling Unit Nos.", NoSeriesMgt.EnsureSeries(NoSeriesCodeTok, NoSeriesDescLbl, StartingNoTok, EndingNoTok));
        Setup.Modify(true);
    end;

    local procedure RegisterFunctionalConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(McpConfigNameTok, McpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Handling Unit", true, true, true);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Handling Unit Line", true, true, true);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Handling Unit", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleUnits()
    var
        DemoHandlingUnit: Codeunit "WHA Demo Handling Unit";
    begin
        DemoHandlingUnit.Import();
    end;
}
