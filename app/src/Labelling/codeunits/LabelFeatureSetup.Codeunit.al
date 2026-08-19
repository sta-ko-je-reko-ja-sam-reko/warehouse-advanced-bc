namespace WarehouseAdvanced.Labelling;

using WarehouseAdvanced.Core;

codeunit 50601 "WHA Label Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Labelling';
        StepDescriptionLbl: Label 'Give handling units the code that goes on their label — a GS1 SSCC your trading partners can read, or a plain licence plate for use inside the warehouse.';
        McpConfigNameTok: Label 'Warehouse Advanced - Labelling', Locked = true;
        McpConfigDescLbl: Label 'Labelling tools. Read the Warehouse Advanced Labelling agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Labelling', Locked = true;
        DemoMcpConfigDescLbl: Label 'Labels the sample handling units. Read the Warehouse Advanced Demo Labelling agent instructions before use.';

    /// <summary>
    /// Adds the labelling step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 80;
        TempSetupStep.Feature := TempSetupStep.Feature::WHALabelling;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Label Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the labelling setup record.
    /// </summary>
    /// <returns>True when labelling is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Label Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for labelling. Never restarts the session; the setup hub owns
    /// the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether labelling should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. Label codes are counted by the labelling setup, not by a number series, because a code has to have a shape GS1 recognises.</param>
    /// <param name="ImportDemoData">Whether to label the sample handling units.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Label Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleLabels();
    end;

    /// <summary>
    /// Ensures the single labelling setup record exists, with defaults applied on first creation. The
    /// company prefix is deliberately left blank: there is no safe default for a number GS1 issues to
    /// one company.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Label Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the labelling MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Label", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Label", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleLabels()
    var
        DemoLabel: Codeunit "WHA Demo Label";
    begin
        DemoLabel.Import();
    end;
}
