namespace WarehouseAdvanced.Replenishment;

codeunit 50257 "WHA Repl. No Demand" implements "WHA IReplDemand"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Only what is in the bin at this moment. Work already planned against the bin is not taken off, so a pick face that is full now looks full even when a wave is about to empty it.';

    /// <summary>
    /// Counts no demand at all. This is what a run did before it could look ahead, kept as a choice
    /// rather than a missing feature: a warehouse whose picks are entered as they are walked has no
    /// planned work to look at, and counting none is the correct answer there.
    /// </summary>
    /// <param name="ReplenishmentRule">Ignored.</param>
    /// <param name="WaveNo">Ignored.</param>
    /// <returns>Zero.</returns>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"; WaveNo: Code[20]): Decimal
    begin
        exit(0);
    end;

    /// <summary>
    /// Describes in one line what this way of counting demand looks at.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
