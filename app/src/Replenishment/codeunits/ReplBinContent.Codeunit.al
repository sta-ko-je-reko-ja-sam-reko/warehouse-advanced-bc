namespace WarehouseAdvanced.Replenishment;

using Microsoft.Warehouse.Structure;

codeunit 50254 "WHA Repl. Bin Content" implements "WHA IReplMethod"
{
    Access = Public;

    var
        DescriptionLbl: Label 'What Business Central believes is in the bin, from its own bin contents.';

    /// <summary>
    /// Measures the pick bin from the standard bin content, which is what the rest of Business Central
    /// works from. A warehouse that posts its movements should use this and no other.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule whose bin is being measured.</param>
    /// <returns>The quantity bin content holds for the rule's item, in the rule's own unit of measure.</returns>
    /// <remarks>
    /// Every bin content row for the item is counted, whatever unit it is held in, and the total is
    /// converted into the rule's unit at the end. Filtering to the rule's unit instead — which is what
    /// this did before — hid stock rather than mis-added it: a rule written in pallets simply could not
    /// see the pieces in its own bin, and reported the face empty while somebody was picking from it.
    /// </remarks>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"): Decimal
    var
        BinContent: Record "Bin Content";
        UnitConvert: Codeunit "WHA Repl. Unit Convert";
        BaseTotal: Decimal;
    begin
        BinContent.SetRange("Location Code", ReplenishmentRule."Location Code");
        BinContent.SetRange("Bin Code", ReplenishmentRule."Bin Code");
        BinContent.SetRange("Item No.", ReplenishmentRule."Item No.");
        BinContent.SetRange("Variant Code", ReplenishmentRule."Variant Code");
        if not BinContent.FindSet() then
            exit(0);

        repeat
            BinContent.CalcFields("Quantity (Base)");
            BaseTotal += BinContent."Quantity (Base)";
        until BinContent.Next() = 0;

        exit(UnitConvert.FromBase(ReplenishmentRule."Item No.", ReplenishmentRule."Unit of Measure Code", BaseTotal));
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
