namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

codeunit 50302 "WHA Slot. Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    var
        StepNameLbl: Label 'Slotting';
        StepDescriptionLbl: Label 'Work out which items move fastest from the picks the warehouse has already done, and find the ones sitting in a worse bin than they deserve.';
        McpConfigNameTok: Label 'Warehouse Advanced - Slotting', Locked = true;
        McpConfigDescLbl: Label 'Item velocity and slotting proposals. Read the Warehouse Advanced Slotting agent instructions before use.';
        DemoMcpConfigNameTok: Label 'Warehouse Advanced - Demo Slotting', Locked = true;
        DemoMcpConfigDescLbl: Label 'Seeds sample slotting data. Read the Warehouse Advanced Demo Slotting agent instructions before use.';

    /// <summary>
    /// Adds the slotting step to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 130;
        TempSetupStep.Feature := TempSetupStep.Feature::WHASlotting;
        TempSetupStep."Has Toggle" := true;
        TempSetupStep.Name := CopyStr(StepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(StepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Slotting Setup";
        TempSetupStep.Insert(true);
    end;

    /// <summary>
    /// Reads the enabled flag from the slotting setup record.
    /// </summary>
    /// <returns>True when slotting is switched on.</returns>
    procedure IsEnabled(): Boolean
    var
        Setup: Record "WHA Slotting Setup";
    begin
        Setup.SetLoadFields("WHA Enabled");
        if not Setup.Get() then
            exit(false);
        exit(Setup."WHA Enabled");
    end;

    /// <summary>
    /// Applies the guided setup choices for slotting. Never restarts the session; the setup hub owns the
    /// single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether slotting should be switched on.</param>
    /// <param name="CreateNoSeries">Ignored. A velocity is keyed by the item it measures and a proposal is numbered by the platform.</param>
    /// <param name="ImportDemoData">Whether to load sample slotting data.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        Setup: Record "WHA Slotting Setup";
    begin
        EnsureSetup(Setup);

        Setup.Validate("WHA Enabled", Enable);
        Setup.Modify(true);

        if ImportDemoData then
            ImportSampleSlotting();
    end;

    /// <summary>
    /// Ensures the single slotting setup record exists, with defaults applied on first creation.
    /// </summary>
    /// <param name="Setup">The setup record to materialise.</param>
    internal procedure EnsureSetup(var Setup: Record "WHA Slotting Setup")
    begin
        Setup.Reset();
        if Setup.Get() then
            exit;

        Setup.Init();
        Setup."Analysis Period Days" := 90;
        Setup."Min Movements" := 2;
        Setup."Class A Percent" := 20;
        Setup."Class B Percent" := 30;
        Setup."Class A Min Bin Ranking" := 80;
        Setup."Class B Min Bin Ranking" := 40;
        Setup.Insert(true);
    end;

    /// <summary>
    /// Creates or refreshes the slotting MCP configurations and the API tools they expose.
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
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Item Velocity", false, false, false);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Slotting Proposal", false, true, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure RegisterDemoConfiguration()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
        ConfigId: Guid;
    begin
        ConfigId := MCPSetup.EnsureConfiguration(DemoMcpConfigNameTok, DemoMcpConfigDescLbl);
        MCPSetup.EnsureApiTool(ConfigId, Page::"WHA API Demo Slotting", false, false, false);
        MCPSetup.Activate(ConfigId);
    end;

    local procedure ImportSampleSlotting()
    var
        DemoSlotting: Codeunit "WHA Demo Slotting";
    begin
        DemoSlotting.Import();
    end;
}
