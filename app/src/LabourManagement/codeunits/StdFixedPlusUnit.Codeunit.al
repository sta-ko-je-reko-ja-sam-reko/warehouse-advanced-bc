namespace WarehouseAdvanced.LabourManagement;

codeunit 50356 "WHA Std. Fixed Plus Unit" implements "WHA ILabourStandard"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The minutes per job, plus the minutes per unit for everything that was handled.';

    /// <summary>
    /// Adds a fixed allowance for the job to a per-unit allowance for what was handled. This is the
    /// ordinary shape of an engineered standard: the walking and the scanning happen once, the picking
    /// happens per unit.
    /// </summary>
    /// <param name="LabourStandard">The standard that applies.</param>
    /// <param name="QuantityHandled">How much was actually moved.</param>
    /// <returns>The expected time in minutes.</returns>
    procedure ExpectedMinutes(var LabourStandard: Record "WHA Labour Standard"; QuantityHandled: Decimal): Decimal
    begin
        if QuantityHandled <= 0 then
            exit(LabourStandard."Minutes Per Job");
        exit(LabourStandard."Minutes Per Job" + (LabourStandard."Minutes Per Unit" * QuantityHandled));
    end;

    /// <summary>
    /// Describes in one line how this basis works out expected time.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
