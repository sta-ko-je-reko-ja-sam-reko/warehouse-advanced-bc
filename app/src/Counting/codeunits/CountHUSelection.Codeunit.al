namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.HandlingUnit;

codeunit 50506 "WHA Count HU Selection" implements "WHA ICountSelection"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Every handling unit standing at this location, one line for each thing a unit says it holds.';

    /// <summary>
    /// Adds a line for every line on every handling unit at the sheet's location, taking what the unit
    /// says it holds as the expected quantity. This is what a warehouse counts when its stock moves as
    /// licence-plated units: the question is not what is in the bin but whether the pallet holds what its
    /// label claims.
    /// </summary>
    /// <param name="CountSheet">The sheet being filled.</param>
    /// <returns>How many lines were added.</returns>
    procedure Fill(var CountSheet: Record "WHA Count Sheet"): Integer
    var
        HandlingUnit: Record "WHA Handling Unit";
        Added: Integer;
    begin
        HandlingUnit.SetLoadFields("No.", "Bin Code");
        HandlingUnit.SetRange("Location Code", CountSheet."Location Code");
        HandlingUnit.SetFilter(Status, '<>%1', HandlingUnit.Status::WHAShipped);
        if not HandlingUnit.FindSet() then
            exit(0);

        repeat
            Added += AddUnitLines(CountSheet, HandlingUnit);
        until HandlingUnit.Next() = 0;

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

    local procedure AddUnitLines(var CountSheet: Record "WHA Count Sheet"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
        Added: Integer;
        LineNo: Integer;
    begin
        HandlingUnitLine.SetLoadFields("Item No.", "Variant Code", "Unit of Measure Code", Quantity, Description);
        HandlingUnitLine.SetRange("Handling Unit No.", HandlingUnit."No.");
        if not HandlingUnitLine.FindSet() then
            exit(0);

        repeat
            LineNo := CountSheetLogic.AddLine(CountSheet, HandlingUnit."Bin Code", HandlingUnitLine."Item No.", HandlingUnitLine."Variant Code", HandlingUnitLine."Unit of Measure Code", HandlingUnit."No.", HandlingUnitLine.Quantity);
            DescribeLine(CountSheet, LineNo, HandlingUnitLine.Description);
            Added += 1;
        until HandlingUnitLine.Next() = 0;

        exit(Added);
    end;

    local procedure DescribeLine(var CountSheet: Record "WHA Count Sheet"; LineNo: Integer; LineDescription: Text[100])
    var
        CountSheetLine: Record "WHA Count Sheet Line";
    begin
        if LineDescription = '' then
            exit;

        CountSheetLine.SetLoadFields(Description);
        if not CountSheetLine.Get(CountSheet."No.", LineNo) then
            exit;

        CountSheetLine.Description := LineDescription;
        CountSheetLine.Modify(true);
    end;
}
