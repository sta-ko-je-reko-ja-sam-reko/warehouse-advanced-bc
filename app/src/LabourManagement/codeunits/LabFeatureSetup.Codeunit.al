namespace WarehouseAdvanced.LabourManagement;

using WarehouseAdvanced.Core;

codeunit 50353 "WHA Lab. Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Labour management';
        StepDescriptionLbl: Label 'Measure the work the warehouse already records. A standard says how long a job should take, finished jobs become recorded time, and the hours nobody spent on a job are recorded too.';
        McpConfigNameTok: Label 'Warehouse Advanced - Labour Management', Locked = true;
        McpConfigDescLbl: Label 'Labour standards and recorded time. Read the Warehouse Advanced Labour Management agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Labour Management', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample labour standards. Read the Warehouse Advanced Demo Labour Management agent instructions before use.';

    /// <summary>
    /// Adds the labour management step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 120;
        TempSetupStep.Feature := TempSetupStep.Feature::WHALabourManagement;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Labour Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the labour setup record.
    /// </summary>
    /// <returns>True when labour management is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Labour Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for labour management. Never restarts the session; the setup hub
    /// owns the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether labour management should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. Recorded time is an event and is numbered by the platform.</param>
    /// <param name="ImportDemoData">Whether to load sample standards.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Labour Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleStandards();
    end;

    /// <summary>
    /// Ensures the single labour setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Labour Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Max Job Minutes" := 240;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the labour MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Labour Standard", true, true, false);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Labour Entry", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Labour", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleStandards()
    var
        DemoLabour: Codeunit "WHA Demo Labour";
    begin
        DemoLabour.Import();
    end;
}
