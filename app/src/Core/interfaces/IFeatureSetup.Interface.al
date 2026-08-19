namespace WarehouseAdvanced.Core;

interface "WHA IFeatureSetup"
{
    /// <summary>
    /// Adds this feature's step to the guided setup list. A feature with nothing to configure
    /// leaves the buffer untouched.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer to add a row to.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary);

    /// <summary>
    /// Determines whether the feature is switched on, normally by reading its own setup record.
    /// </summary>
    /// <returns>True when the feature is enabled.</returns>
    procedure IsEnabled(): Boolean;

    /// <summary>
    /// Applies the choices made in the guided setup wizard for this feature. Must not restart the
    /// session; the setup hub owns the single deferred restart.
    /// </summary>
    /// <param name="Enable">Whether the feature should be switched on.</param>
    /// <param name="CreateNoSeries">Whether to create and assign the feature's number series.</param>
    /// <param name="ImportDemoData">Whether to load the feature's sample data.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean);

    /// <summary>
    /// Creates or refreshes this feature's MCP configuration and the API tools it exposes, so an agent
    /// can be bound to the feature's API group. Must be idempotent — it runs on install and upgrade.
    /// A feature with no API surface does nothing.
    /// </summary>
    procedure RegisterMcpConfiguration();
}
