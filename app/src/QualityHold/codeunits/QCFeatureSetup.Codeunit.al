namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;

codeunit 50552 "WHA QC Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Quality hold';
        StepDescriptionLbl: Label 'Stop goods from being used while somebody decides what to do with them. Holding a pallet holds what is inside it, no work can be planned for it, and scrapping it writes the stock off the way you choose to.';
        McpConfigNameTok: Label 'Warehouse Advanced - Quality Hold', Locked = true;
        McpConfigDescLbl: Label 'Quality hold tools. Read the Warehouse Advanced Quality Hold agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Quality Hold', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample quality holds. Read the Warehouse Advanced Demo Quality Hold agent instructions before use.';

    /// <summary>
    /// Adds the quality hold step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 110;
        TempSetupStep.Feature := TempSetupStep.Feature::WHAQualityHold;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Quality Hold Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the quality hold setup record.
    /// </summary>
    /// <returns>True when quality hold is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Quality Hold Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for quality hold. Never restarts the session; the setup hub owns
    /// the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether quality hold should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. A hold is an event and is numbered by the platform.</param>
    /// <param name="ImportDemoData">Whether to load sample holds.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Quality Hold Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleHolds();
    end;

    /// <summary>
    /// Ensures the single quality hold setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Quality Hold Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Hold Nested Units" := true;
        Setup."Require Disposition" := true;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the quality hold MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Quality Hold", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Quality Hold", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleHolds()
    var
        DemoQualityHold: Codeunit "WHA Demo Quality Hold";
    begin
        DemoQualityHold.Import();
    end;
}
