namespace WarehouseAdvanced.LabourManagement;

codeunit 50357 "WHA Std. Fixed Only" implements "WHA ILabourStandard"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The minutes per job, whatever was handled. The minutes per unit are ignored.';

    /// <summary>
    /// Allows the same time for every job of this kind. Right where the quantity is not what takes the
    /// time — moving one whole pallet takes as long whether it holds ten cases or a hundred.
    /// </summary>
    /// <param name="LabourStandard">The standard that applies.</param>
    /// <param name="QuantityHandled">How much was actually moved. Ignored.</param>
    /// <returns>The expected time in minutes.</returns>
    procedure ExpectedMinutes(var LabourStandard: Record "WHA Labour Standard"; QuantityHandled: Decimal): Decimal
    begin
        exit(LabourStandard."Minutes Per Job");
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
