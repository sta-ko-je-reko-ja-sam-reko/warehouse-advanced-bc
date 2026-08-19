namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

codeunit 50651 "WHA Int. Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Integration';
        StepDescriptionLbl: Label 'Exchange messages with the system that talks to the warehouse: take in receipts and work requests, and put confirmations in an outbox to be collected.';
        McpConfigNameTok: Label 'Warehouse Advanced - Integration', Locked = true;
        McpConfigDescLbl: Label 'Integration inbox and outbox tools. Read the Warehouse Advanced Integration agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Integration', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample integration messages. Read the Warehouse Advanced Demo Integration agent instructions before use.';
        DefaultPartnerTok: Label 'HOST', Locked = true;

    /// <summary>
    /// Adds the integration step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 40;
        TempSetupStep.Feature := TempSetupStep.Feature::WHAIntegration;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Integration Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the integration setup record.
    /// </summary>
    /// <returns>True when the integration surface is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Integration Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for the integration surface. Never restarts the session; the
    /// setup hub owns the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether the integration surface should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. Messages are numbered by the platform, not by a number series.</param>
    /// <param name="ImportDemoData">Whether to load sample messages.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Integration Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleMessages();
    end;

    /// <summary>
    /// Ensures the single integration setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Integration Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Partner System" := CopyStr(DefaultPartnerTok, 1, MaxStrLen(Setup."Partner System"));
        Setup."Max Retry Count" := 3;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the integration MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Integration Message", true, true, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Integration", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleMessages()
    var
        DemoIntegration: Codeunit "WHA Demo Integration";
    begin
        DemoIntegration.Import();
    end;
}
