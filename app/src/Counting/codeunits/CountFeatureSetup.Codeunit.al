namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

codeunit 50502 "WHA Count Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Counting';
        StepDescriptionLbl: Label 'Count part of the warehouse while it keeps working. A sheet says what to count, the floor counts it without seeing what was expected, and anything that comes out wrong by more than you allow has to be looked at before the sheet is closed.';
        NoSeriesCodeTok: Label 'WHA-COUNT', Locked = true;
        NoSeriesDescLbl: Label 'Warehouse advanced count sheets';
        StartingNoTok: Label 'CS000001', Locked = true;
        EndingNoTok: Label 'CS999999', Locked = true;
        McpConfigNameTok: Label 'Warehouse Advanced - Counting', Locked = true;
        McpConfigDescLbl: Label 'Count sheet tools. Read the Warehouse Advanced Counting agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Counting', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample count sheets. Read the Warehouse Advanced Demo Counting agent instructions before use.';

    /// <summary>
    /// Adds the counting step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 100;
        TempSetupStep.Feature := TempSetupStep.Feature::WHACounting;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep."Has No. Series" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Count Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the counting setup record.
    /// </summary>
    /// <returns>True when counting is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Count Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for counting. Never restarts the session; the setup hub owns the
    /// single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether counting should be switched on.</param>
    /// <param name="CreateNoSeries">Whether to create the number series that numbers count sheets, and assign it to this feature's own setup.</param>
    /// <param name="ImportDemoData">Whether to load sample count sheets.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Count Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if CreateNoSeries then
            EnsureNoSeries(Setup);

        if ImportDemoData then
            ImportSampleSheets();
    end;

    /// <summary>
    /// Ensures the single counting setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Count Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Blind Counting" := true;
        Setup."Tolerance Percent" := 2;
        Setup."Approve Variances" := true;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the counting MCP configurations and the API tools they expose.
    /// </summary>
    procedure RegisterMcpConfiguration()
    begin
        RegisterFunctionalConfiguration();
        RegisterDemoConfiguration();
    end;

    local procedure EnsureNoSeries(var Setup: Record "WHA Count Setup")
    var
        NoSeriesMgt: Codeunit "WHA No. Series Mgt.";
    begin
        if Setup."Count Sheet Nos." <> '' then
            exit;

        Setup.Validate("Count Sheet Nos.", NoSeriesMgt.EnsureSeries(NoSeriesCodeTok, NoSeriesDescLbl, StartingNoTok, EndingNoTok));
        Setup.Modify(true);
    end;

    local procedure RegisterFunctionalConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(McpConfigNameTok, McpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Count Sheet", true, true, false);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Count Sheet Line", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Count", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleSheets()
    var
        DemoCount: Codeunit "WHA Demo Count";
    begin
        DemoCount.Import();
    end;
}
