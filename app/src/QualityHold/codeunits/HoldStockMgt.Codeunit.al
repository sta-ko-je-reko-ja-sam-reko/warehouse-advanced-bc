namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

codeunit 50564 "WHA Hold Stock Mgt."
{
    Access = Public;

    /// <summary>
    /// Tells Business Central that goods are quarantined, in whatever way the quality hold setup asks
    /// for. This is the single place the feature calls, so placing a hold never learns what any policy
    /// does to Business Central's own records.
    /// </summary>
    /// <param name="QualityHold">The hold being placed.</param>
    /// <param name="HandlingUnit">The unit being held.</param>
    /// <returns>How many things in Business Central were blocked.</returns>
    internal procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    var
        HoldStockPolicy: Interface "WHA IHoldStockPolicy";
    begin
        HoldStockPolicy := PolicyOf();
        exit(HoldStockPolicy.Apply(QualityHold, HandlingUnit));
    end;

    /// <summary>
    /// Lets the goods go again when a hold closes, whatever the disposition was.
    /// </summary>
    /// <remarks>
    /// Scrapping is not a reason to leave the block standing. What is scrapped is written off by posting;
    /// leaving a lot or a bin blocked afterwards would hold back the good stock that is still there,
    /// forever, with nothing in this app left pointing at why.
    /// </remarks>
    /// <param name="QualityHold">The hold being closed.</param>
    /// <param name="HandlingUnit">The unit that was held.</param>
    /// <returns>How many things in Business Central were released.</returns>
    internal procedure Lift(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    var
        HoldStockPolicy: Interface "WHA IHoldStockPolicy";
    begin
        HoldStockPolicy := PolicyOf();
        exit(HoldStockPolicy.Lift(QualityHold, HandlingUnit));
    end;

    /// <summary>
    /// Describes in one line what the chosen policy does to Business Central.
    /// </summary>
    /// <param name="Policy">The policy chosen in the quality hold setup.</param>
    /// <returns>A short description in the user's language.</returns>
    internal procedure Describe(Policy: Enum "WHA Hold Stock Policy"): Text
    var
        HoldStockPolicy: Interface "WHA IHoldStockPolicy";
    begin
        HoldStockPolicy := Policy;
        exit(HoldStockPolicy.Describe());
    end;

    /// <summary>
    /// Answers whether some other hold that is still live stands on the same bin.
    /// </summary>
    /// <remarks>
    /// Business Central blocks a bin, not a pallet. Two pallets in one bin therefore share one block, and
    /// releasing the first must not free stock the second is still questioning.
    /// </remarks>
    /// <param name="QualityHold">The hold being closed, which is excluded from the answer.</param>
    /// <param name="HandlingUnit">The unit that was held.</param>
    /// <returns>True when the block has to stay.</returns>
    internal procedure AnotherHoldStandsOnBin(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Boolean
    var
        OtherHold: Record "WHA Quality Hold";
    begin
        if (HandlingUnit."Location Code" = '') or (HandlingUnit."Bin Code" = '') then
            exit(false);

        OtherHold.SetFilter("Entry No.", '<>%1', QualityHold."Entry No.");
        OtherHold.SetRange("Location Code", HandlingUnit."Location Code");
        OtherHold.SetRange("Bin Code", HandlingUnit."Bin Code");
        OtherHold.SetRange(Status, OtherHold.Status::WHAOnHold);
        exit(not OtherHold.IsEmpty());
    end;

    /// <summary>
    /// Answers whether some other hold that is still live stands on the same lot of the same item.
    /// </summary>
    /// <param name="QualityHold">The hold being closed, which is excluded from the answer.</param>
    /// <param name="ItemNo">The item the lot belongs to.</param>
    /// <param name="LotNo">The lot.</param>
    /// <returns>True when the block has to stay.</returns>
    internal procedure AnotherHoldStandsOnLot(var QualityHold: Record "WHA Quality Hold"; ItemNo: Code[20]; LotNo: Code[50]): Boolean
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        OtherHold: Record "WHA Quality Hold";
    begin
        if (ItemNo = '') or (LotNo = '') then
            exit(false);

        OtherHold.SetLoadFields("Handling Unit No.");
        OtherHold.SetFilter("Entry No.", '<>%1', QualityHold."Entry No.");
        OtherHold.SetRange(Status, OtherHold.Status::WHAOnHold);
        if not OtherHold.FindSet() then
            exit(false);

        repeat
            HandlingUnitLine.SetRange("Handling Unit No.", OtherHold."Handling Unit No.");
            HandlingUnitLine.SetRange("Item No.", ItemNo);
            HandlingUnitLine.SetRange("Lot No.", LotNo);
            if not HandlingUnitLine.IsEmpty() then
                exit(true);
        until OtherHold.Next() = 0;

        exit(false);
    end;

    local procedure PolicyOf(): Enum "WHA Hold Stock Policy"
    var
        Setup: Record "WHA Quality Hold Setup";
        Policy: Enum "WHA Hold Stock Policy";
    begin
        Setup.SetLoadFields("Hold Blocks Stock");
        if not Setup.Get() then
            exit(Policy::WHARecordOnly);
        exit(Setup."Hold Blocks Stock");
    end;
}
