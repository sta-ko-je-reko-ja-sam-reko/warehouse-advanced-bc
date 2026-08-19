namespace WarehouseAdvanced.Core;

codeunit 50005 "WHA Default Feature Setup" implements "WHA IFeatureSetup"
{
    Access = Public;

    /// <summary>
    /// Adds no step. A feature value that has not bound its own implementation contributes nothing
    /// to the guided setup list.
    /// </summary>
    /// <param name="TempSetupStep">The guided setup step buffer, left untouched.</param>
    procedure RegisterStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
    end;

    /// <summary>
    /// Reports the feature as switched off, which is the correct answer for a feature value with no
    /// implementation behind it.
    /// </summary>
    /// <returns>Always false.</returns>
    procedure IsEnabled(): Boolean
    begin
        exit(false);
    end;

    /// <summary>
    /// Applies nothing. A feature value with no implementation has no settings to apply.
    /// </summary>
    /// <param name="Enable">Ignored.</param>
    /// <param name="CreateNoSeries">Ignored.</param>
    /// <param name="ImportDemoData">Ignored.</param>
    procedure ApplyChoices(Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    begin
    end;
}
