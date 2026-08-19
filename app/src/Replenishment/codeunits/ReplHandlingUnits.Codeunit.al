namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.HandlingUnit;

codeunit 50255 "WHA Repl. Handling Units" implements "WHA IReplMethod"
{
    Access = Public;

    var
        DescriptionLbl: Label 'What the handling units standing in the bin say they hold.';

    /// <summary>
    /// Measures the pick bin from the handling units standing in it. For a warehouse whose stock moves
    /// as licence-plated units, this is the number the floor would give you if you asked, and it can
    /// differ from bin content until the movements are posted. Only units that are available count: a
    /// pallet on hold is standing in the bin and cannot be picked from, so counting it would leave the
    /// pick face empty and the rule satisfied.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule whose bin is being measured.</param>
    /// <returns>The quantity the units in the bin hold of the rule's item.</returns>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"): Decimal
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        Total: Decimal;
    begin
        HandlingUnit.SetLoadFields("No.");
        HandlingUnit.SetRange("Location Code", ReplenishmentRule."Location Code");
        HandlingUnit.SetRange("Bin Code", ReplenishmentRule."Bin Code");
        HandlingUnit.SetFilter(Status, '%1|%2', HandlingUnit.Status::WHAOpen, HandlingUnit.Status::WHAClosed);
        if not HandlingUnit.FindSet() then
            exit(0);

        repeat
            HandlingUnitLine.SetRange("Handling Unit No.", HandlingUnit."No.");
            HandlingUnitLine.SetRange("Item No.", ReplenishmentRule."Item No.");
            HandlingUnitLine.SetRange("Variant Code", ReplenishmentRule."Variant Code");
            HandlingUnitLine.CalcSums(Quantity);
            Total += HandlingUnitLine.Quantity;
        until HandlingUnit.Next() = 0;

        exit(Total);
    end;

    /// <summary>
    /// Describes in one line where this method gets its number from.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
