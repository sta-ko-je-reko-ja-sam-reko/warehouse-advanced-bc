namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

codeunit 50401 "WHA Pack Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Packing';
        StepDescriptionLbl: Label 'Pack goods into cartons at a bench, check what went in, and close the carton — which becomes a handling unit like any other.';
        McpConfigNameTok: Label 'Warehouse Advanced - Packing', Locked = true;
        McpConfigDescLbl: Label 'Packing tools. Read the Warehouse Advanced Packing agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Packing', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample packing benches. Read the Warehouse Advanced Demo Packing agent instructions before use.';

    /// <summary>
    /// Adds the packing step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 70;
        TempSetupStep.Feature := TempSetupStep.Feature::WHAPacking;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Pack Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the packing setup record.
    /// </summary>
    /// <returns>True when packing is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Pack Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for packing. Never restarts the session; the setup hub owns the
    /// single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether packing should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. A carton is numbered as the handling unit it is, from the foundation series.</param>
    /// <param name="ImportDemoData">Whether to load sample packing benches.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Pack Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleStations();
    end;

    /// <summary>
    /// Ensures the single packing setup record exists, with defaults applied on first creation. Both
    /// checking and closing the carton start switched on, because a packing station that checks nothing
    /// and leaves cartons open is not doing the job people think it is.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Pack Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Require Verification" := true;
        Setup."Close Unit When Closed" := true;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the packing MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Pack Station", true, true, false);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Pack Session", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Pack", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleStations()
    var
        DemoPack: Codeunit "WHA Demo Pack";
    begin
        DemoPack.Import();
    end;
}
