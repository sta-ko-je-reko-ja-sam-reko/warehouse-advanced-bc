namespace WarehouseAdvanced.Core;

codeunit 50004 "WHA Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        EnsureSetupRecord();
        RegisterGuidedSetup();
        RegisterMcpConfigurations();
    end;

    local procedure EnsureSetupRecord()
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        SetupLogic.EnsureExists(WarehouseSetup);
    end;

    local procedure RegisterGuidedSetup()
    var
        GuidedSetup: Codeunit "WHA Guided Setup";
    begin
        GuidedSetup.RegisterAssistedSetup();
    end;

    local procedure RegisterMcpConfigurations()
    var
        MCPSetup: Codeunit "WHA MCP Setup";
    begin
        MCPSetup.EnsureConfigurations();
    end;
}
