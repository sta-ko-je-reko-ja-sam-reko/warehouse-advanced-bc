namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

codeunit 50151 "WHA Wave Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Wave management';
        StepDescriptionLbl: Label 'Gather warehouse work into waves and send each one to the floor as a batch, so a shift, a departure or a round of picking starts and finishes together.';
        NoSeriesCodeTok: Label 'WHA-WAVE', Locked = true;
        NoSeriesDescLbl: Label 'Warehouse advanced waves';
        StartingNoTok: Label 'WV000001', Locked = true;
        EndingNoTok: Label 'WV999999', Locked = true;
        McpConfigNameTok: Label 'Warehouse Advanced - Wave Management', Locked = true;
        McpConfigDescLbl: Label 'Wave tools. Read the Warehouse Advanced Wave Management agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Wave Management', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample waves. Read the Warehouse Advanced Demo Wave Management agent instructions before use.';

    /// <summary>
    /// Adds the wave management step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 60;
        TempSetupStep.Feature := TempSetupStep.Feature::WHAWaveManagement;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep."Has No. Series" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Wave Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the wave setup record.
    /// </summary>
    /// <returns>True when wave management is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Wave Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for wave management. Never restarts the session; the setup hub
    /// owns the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether wave management should be switched on.</param>
    /// <param name="CreateNoSeries">Whether to create the number series that numbers waves, and assign it to this feature's own setup.</param>
    /// <param name="ImportDemoData">Whether to load sample waves.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Wave Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if CreateNoSeries then
            EnsureNoSeries(Setup);

        if ImportDemoData then
            ImportSampleWaves();
    end;

    /// <summary>
    /// Ensures the single wave setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Wave Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Default Max Tasks" := 25;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the wave MCP configurations and the API tools they expose.
    /// </summary>
    procedure RegisterMcpConfiguration()
    begin
        RegisterFunctionalConfiguration();
        RegisterDemoConfiguration();
    end;

    local procedure EnsureNoSeries(var Setup: Record "WHA Wave Setup")
    var
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
    begin
        if Setup."Wave Nos." <> '' then
            exit;

        Setup.Validate("Wave Nos.", NoSeriesMgt.EnsureSeries(NoSeriesCodeTok, NoSeriesDescLbl, StartingNoTok, EndingNoTok));
        Setup.Modify(true);
    end;

    local procedure RegisterFunctionalConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(McpConfigNameTok, McpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Wave", true, true, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Wave", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleWaves()
    var
        DemoWave: Codeunit "WHA Demo Wave";
    begin
        DemoWave.Import();
    end;
}
