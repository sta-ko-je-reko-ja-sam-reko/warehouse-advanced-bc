namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.Core;

codeunit 50702 "WHA KPI Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Analytics';
        StepDescriptionLbl: Label 'Turn what the app has already recorded into a handful of numbers about how the warehouse is running, and keep them so this month can be compared with last.';
        McpConfigNameTok: Label 'Warehouse Advanced - Analytics', Locked = true;
        McpConfigDescLbl: Label 'Warehouse KPI figures. Read the Warehouse Advanced Analytics agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Analytics', Locked = true;
        DemoMcpConfigDescLbl: Label 'Captures a first set of KPI figures. Read the Warehouse Advanced Demo Analytics agent instructions before use.';

    /// <summary>
    /// Adds the analytics step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 150;
        TempSetupStep.Feature := TempSetupStep.Feature::WHAAnalytics;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Analytics Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the analytics setup record.
    /// </summary>
    /// <returns>True when analytics is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Analytics Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for analytics. Never restarts the session; the setup hub owns the
    /// single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether analytics should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. A figure is numbered by the platform.</param>
    /// <param name="ImportDemoData">Whether to capture a first set of figures.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Analytics Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleAnalytics();
    end;

    /// <summary>
    /// Ensures the single analytics setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Analytics Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Default Period Days" := 7;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the analytics MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API KPI Snapshot", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Analytics", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleAnalytics()
    var
        DemoAnalytics: Codeunit "WHA Demo Analytics";
    begin
        DemoAnalytics.Import();
    end;
}
