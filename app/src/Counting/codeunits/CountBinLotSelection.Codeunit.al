namespace WarehouseAdvanced.Counting;

codeunit 50509 "WHA Count Bin Lot Selection" implements "WHA ICountSelection"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Every lot and serial number Business Central believes is in a bin at this location, one line for each. This is the selection to use where items are tracked: the bins selection gathers a bin''s whole quantity across every lot in it, which leaves nothing to post an adjustment against.';

    /// <summary>
    /// Adds a line for every combination of bin, item, variant, unit of measure, lot and serial number
    /// that the warehouse entries at this location add up to. Reading the entries rather than bin content
    /// is what makes the lot visible: bin content aggregates across lots, so it can say a bin holds 40
    /// but never that the 40 is 25 of one lot and 15 of another.
    /// </summary>
    /// <param name="CountSheet">The sheet being filled.</param>
    /// <returns>How many lines were added.</returns>
    procedure Fill(var CountSheet: Record "WHA Count Sheet"): Integer
    var
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        StockByLot: Query "WHA Whse Stock By Lot";
        Added: Integer;
        LineNo: Integer;
    begin
        StockByLot.SetRange(locationCodeFilter, CountSheet."Location Code");
        StockByLot.Open();

        while StockByLot.Read() do
            if StockByLot.quantity <> 0 then begin
                LineNo := CountSheetLogic.AddLine(CountSheet, StockByLot.binCode, StockByLot.itemNo, StockByLot.variantCode, StockByLot.unitOfMeasureCode, '', StockByLot.quantity);
                CountSheetLogic.SetLineDetails(CountSheet, LineNo, '', StockByLot.lotNo, StockByLot.serialNo);
                Added += 1;
            end;

        StockByLot.Close();
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
