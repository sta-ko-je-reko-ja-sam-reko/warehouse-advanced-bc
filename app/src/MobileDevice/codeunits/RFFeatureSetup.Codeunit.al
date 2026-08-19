namespace WarehouseAdvanced.MobileDevice;

using WarehouseAdvanced.Core;

codeunit 50101 "WHA RF Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Handheld';
        StepDescriptionLbl: Label 'A scanner-shaped screen over the work queue: an operator signs in on a device, asks for the next job, and scans their way through it.';
        McpConfigNameTok: Label 'Warehouse Advanced - Mobile Device', Locked = true;
        McpConfigDescLbl: Label 'Handheld device tools. Read the Warehouse Advanced Mobile Device agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Mobile Device', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample handheld devices. Read the Warehouse Advanced Demo Mobile Device agent instructions before use.';

    /// <summary>
    /// Adds the handheld step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 50;
        TempSetupStep.Feature := TempSetupStep.Feature::WHAMobileDevice;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA RF Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the handheld setup record.
    /// </summary>
    /// <returns>True when the handheld screen is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA RF Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for the handheld. Never restarts the session; the setup hub owns
    /// the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether the handheld screen should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. Devices are given codes by the people who label them.</param>
    /// <param name="ImportDemoData">Whether to load sample devices.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA RF Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleDevices();
    end;

    /// <summary>
    /// Ensures the single handheld setup record exists, with defaults applied on first creation. Scanning
    /// is required by default, because a handheld that does not check where the operator is standing is
    /// only a slower desktop.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA RF Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Confirm By Scan" := true;
        Setup."Auto Start Task" := true;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the handheld MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API RF Device", true, true, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo RF Device", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleDevices()
    var
        DemoRFDevice: Codeunit "WHA Demo RF Device";
    begin
        DemoRFDevice.Import();
    end;
}
