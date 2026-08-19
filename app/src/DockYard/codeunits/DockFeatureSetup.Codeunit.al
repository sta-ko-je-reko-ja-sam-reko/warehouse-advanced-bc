namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

codeunit 50452 "WHA Dock Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Dock and yard';
        StepDescriptionLbl: Label 'Book vehicles onto doors before they turn up, know which trailer is standing where in the yard, and keep the times a visit actually took.';
        McpConfigNameTok: Label 'Warehouse Advanced - Dock and Yard', Locked = true;
        McpConfigDescLbl: Label 'Dock doors, yard positions and appointments. Read the Warehouse Advanced Dock and Yard agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Dock and Yard', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample doors, yard positions and appointments. Read the Warehouse Advanced Demo Dock and Yard agent instructions before use.';

    /// <summary>
    /// Adds the dock and yard step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 140;
        TempSetupStep.Feature := TempSetupStep.Feature::WHADockYard;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Dock Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the dock and yard setup record.
    /// </summary>
    /// <returns>True when dock and yard is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Dock Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for dock and yard. Never restarts the session; the setup hub owns
    /// the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether dock and yard should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. The dock appointment number series belongs to the foundation step.</param>
    /// <param name="ImportDemoData">Whether to load sample doors, yard positions and appointments.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Dock Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleDock();
    end;

    /// <summary>
    /// Ensures the single dock and yard setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Dock Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Default Slot Minutes" := 60;
        Setup."Late Threshold Minutes" := 30;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the dock and yard MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Dock Door", false, false, false);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Yard Position", false, false, false);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Dock Appointment", true, true, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Dock", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleDock()
    var
        DemoDock: Codeunit "WHA Demo Dock";
    begin
        DemoDock.Import();
    end;
}
