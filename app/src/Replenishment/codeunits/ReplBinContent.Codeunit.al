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
    /// <returns>The quantity bin content holds for the rule's item.</returns>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"): Decimal
    var
        BinContent: Record "Bin Content";
        Total: Decimal;
    begin
        BinContent.SetLoadFields("Location Code", "Bin Code", "Item No.", "Variant Code");
        BinContent.SetRange("Location Code", ReplenishmentRule."Location Code");
        BinContent.SetRange("Bin Code", ReplenishmentRule."Bin Code");
        BinContent.SetRange("Item No.", ReplenishmentRule."Item No.");
        BinContent.SetRange("Variant Code", ReplenishmentRule."Variant Code");
        if ReplenishmentRule."Unit of Measure Code" <> '' then
            BinContent.SetRange("Unit of Measure Code", ReplenishmentRule."Unit of Measure Code");
        if not BinContent.FindSet() then
            exit(0);

        repeat
            BinContent.CalcFields(Quantity);
            Total += BinContent.Quantity;
        until BinContent.Next() = 0;

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
