namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

codeunit 50251 "WHA Repl. Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Replenishment';
        StepDescriptionLbl: Label 'Keep the bins people pick from full. A rule says how low a bin may run and how full to fill it, and a run raises the work to top it up before anybody finds it empty.';
        McpConfigNameTok: Label 'Warehouse Advanced - Replenishment', Locked = true;
        McpConfigDescLbl: Label 'Replenishment rules and runs. Read the Warehouse Advanced Replenishment agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Replenishment', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample replenishment rules. Read the Warehouse Advanced Demo Replenishment agent instructions before use.';

    /// <summary>
    /// Adds the replenishment step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 90;
        TempSetupStep.Feature := TempSetupStep.Feature::WHAReplenishment;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Repl. Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the replenishment setup record.
    /// </summary>
    /// <returns>True when replenishment is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Repl. Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for replenishment. Never restarts the session; the setup hub owns
    /// the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether replenishment should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. Replenishment rules are identified by the bin they look after, not by a number.</param>
    /// <param name="ImportDemoData">Whether to load sample replenishment rules.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Repl. Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleRules();
    end;

    /// <summary>
    /// Ensures the single replenishment setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Repl. Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Default Priority" := 20;
        Setup."Release Replenishment Work" := true;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the replenishment MCP configurations and the API tools they expose.
    /// </summary>
    procedure RegisterMcpConfiguration()
    begin
        RegisterFunctionalConfiguration();
        RegisterDemoConfiguration();
    end;

    local procedure RegisterFunctionalConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(McpConfigNameTok, McpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Repl. Rule", true, true, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Repl.", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleRules()
    var
        DemoReplenishment: Codeunit "WHA Demo Replenishment";
    begin
        DemoReplenishment.Import();
    end;
}
