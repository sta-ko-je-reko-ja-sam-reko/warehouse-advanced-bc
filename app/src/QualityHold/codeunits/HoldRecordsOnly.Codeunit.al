namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

codeunit 50561 "WHA Hold Records Only" implements "WHA IHoldStockPolicy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The hold is recorded here and Business Central is not told. It will go on offering the goods to orders, planning and picks, and only somebody reading this app knows they are quarantined.';

    /// <summary>
    /// Stops nothing. This is what the app did before it could reach into Business Central at all, kept
    /// as a choice rather than a missing feature: a warehouse whose quality process is advisory, or which
    /// blocks stock by a route of its own, has not asked this app to touch its master data.
    /// </summary>
    /// <param name="QualityHold">The hold being placed. Ignored.</param>
    /// <param name="HandlingUnit">The unit being held. Ignored.</param>
    /// <returns>Zero.</returns>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Undoes nothing, because nothing was done.
    /// </summary>
    /// <param name="QualityHold">The hold being closed. Ignored.</param>
    /// <param name="HandlingUnit">The unit that was held. Ignored.</param>
    /// <returns>Zero.</returns>
    procedure Lift(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Describes in one line what this policy does to Business Central.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
