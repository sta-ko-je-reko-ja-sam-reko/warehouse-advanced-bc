namespace WarehouseAdvanced.Counting;

using Microsoft.Warehouse.Structure;

codeunit 50505 "WHA Count Bin Selection" implements "WHA ICountSelection"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Every item Business Central believes is in a bin at this location, one line for each.';

    /// <summary>
    /// Adds a line for every bin content record at the sheet's location, taking what Business Central
    /// believes is there as the expected quantity. A bin content of zero is still counted: an empty bin
    /// the system thinks is empty is worth confirming, and one that is not empty is exactly the finding
    /// a count exists for.
    /// </summary>
    /// <param name="CountSheet">The sheet being filled.</param>
    /// <returns>How many lines were added.</returns>
    procedure Fill(var CountSheet: Record "WHA Count Sheet"): Integer
    var
        BinContent: Record "Bin Content";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Added: Integer;
    begin
        BinContent.SetLoadFields("Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
        BinContent.SetRange("Location Code", CountSheet."Location Code");
        if not BinContent.FindSet() then
            exit(0);

        repeat
            BinContent.CalcFields(Quantity);
            CountSheetLogic.AddLine(CountSheet, BinContent."Bin Code", BinContent."Item No.", BinContent."Variant Code", BinContent."Unit of Measure Code", '', BinContent.Quantity);
            Added += 1;
        until BinContent.Next() = 0;

        exit(Added);
    end;

    /// <summary>
    /// Describes in one line what this selection gathers.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
