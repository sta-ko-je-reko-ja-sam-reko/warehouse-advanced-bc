namespace WarehouseAdvanced.Core;

using System.MCP;

codeunit 50006 "WHA MCP Setup"
{
    Access = Internal;

    /// <summary>
    /// Creates or refreshes every MCP configuration the app owns, one per feature. The foundation owns
    /// none: it holds no data worth exposing, because every setting belongs to the feature that uses it.
    /// Idempotent, so it is safe to run on both install and upgrade.
    /// </summary>
    internal procedure EnsureConfigurations()
    var
        FeatureSetup: Interface "WHA IFeatureSetup";
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            FeatureSetup := Enum::"WHA Feature".FromInteger(Ordinal);
            FeatureSetup.RegisterMcpConfiguration();
        end;
    end;

    /// <summary>
    /// Returns the configuration with the given name, creating it if it does not exist yet.
    /// </summary>
    /// <param name="Name">The configuration name. Must not be translated, because it is the lookup key.</param>
    /// <param name="Description">Short pointer text shown on the configuration card.</param>
    /// <returns>The configuration id.</returns>
    internal procedure EnsureConfiguration(Name: Text[100]; Description: Text[250]): Guid
    var
        MCPConfig: Codeunit "MCP Config";
        ConfigId: Guid;
    begin
        ConfigId := MCPConfig.GetConfigurationIdByName(Name);
        if not IsNullGuid(ConfigId) then
            exit(ConfigId);

        exit(MCPConfig.CreateConfiguration(Name, Description));
    end;

    /// <summary>
    /// Adds an API page to a configuration as a tool and sets what the agent may do with it. Reading is
    /// always allowed; the write verbs are per tool.
    /// </summary>
    /// <param name="ConfigId">The configuration to add the tool to.</param>
    /// <param name="ApiPageId">The API page exposed as the tool.</param>
    /// <param name="AllowCreate">Whether the agent may create records.</param>
    /// <param name="AllowModify">Whether the agent may change records.</param>
    /// <param name="AllowDelete">Whether the agent may delete records.</param>
    internal procedure EnsureApiTool(ConfigId: Guid; ApiPageId: Integer; AllowCreate: Boolean; AllowModify: Boolean; AllowDelete: Boolean)
    var
        MCPConfig: Codeunit "MCP Config";
        ToolId: Guid;
    begin
        ToolId := MCPConfig.GetAPIToolId(ConfigId, ApiPageId);
        if IsNullGuid(ToolId) then
            ToolId := MCPConfig.CreateAPITool(ConfigId, ApiPageId);

        MCPConfig.AllowRead(ToolId, true);
        MCPConfig.AllowCreate(ToolId, AllowCreate);
        MCPConfig.AllowModify(ToolId, AllowModify);
        MCPConfig.AllowDelete(ToolId, AllowDelete);
    end;

    /// <summary>
    /// Activates a configuration so connected agents can bind to it.
    /// </summary>
    /// <param name="ConfigId">The configuration to activate.</param>
    internal procedure Activate(ConfigId: Guid)
    var
        MCPConfig: Codeunit "MCP Config";
    begin
        MCPConfig.ActivateConfiguration(ConfigId, true);
    end;
}
