namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

codeunit 50201 "WHA Task Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Directed work';
        StepDescriptionLbl: Label 'Queue warehouse work as numbered tasks, give each one a priority, and hand the most urgent one to whoever asks for work next.';
        McpConfigNameTok: Label 'Warehouse Advanced - Directed Work', Locked = true;
        McpConfigDescLbl: Label 'Warehouse task tools. Read the Warehouse Advanced Directed Work agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Directed Work', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample warehouse tasks. Read the Warehouse Advanced Demo Directed Work agent instructions before use.';

    /// <summary>
    /// Adds the directed work step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 30;
        TempSetupStep.Feature := TempSetupStep.Feature::WHADirectedWork;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Warehouse Task Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the warehouse task setup record.
    /// </summary>
    /// <returns>True when directed work is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Warehouse Task Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for directed work. Never restarts the session; the setup hub
    /// owns the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether directed work should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. The warehouse task number series belongs to the foundation step.</param>
    /// <param name="ImportDemoData">Whether to load sample warehouse tasks.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Warehouse Task Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleTasks();
    end;

    /// <summary>
    /// Ensures the single warehouse task setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Warehouse Task Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Default Priority" := DefaultPriority();
        Setup.Insert(true);
    end;

    /// <summary>
    /// The priority a task gets when nobody sets one, and the value a new setup record starts with.
    /// </summary>
    /// <returns>The middle of the priority range, so more and less urgent work both fit around it.</returns>
    internal procedure DefaultPriority(): Integer
    begin
        exit(100);
    end;

    /// <summary>
    /// Creates or refreshes the directed work MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Warehouse Task", true, true, true);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Warehouse Task", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleTasks()
    var
        DemoWarehouseTask: Codeunit "WHA Demo Warehouse Task";
    begin
        DemoWarehouseTask.Import();
    end;
}
