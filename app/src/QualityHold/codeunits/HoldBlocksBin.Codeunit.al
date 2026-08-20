namespace WarehouseAdvanced.QualityHold;

using Microsoft.Warehouse.Structure;
using WarehouseAdvanced.HandlingUnit;

codeunit 50562 "WHA Hold Blocks Bin" implements "WHA IHoldStockPolicy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Movement in and out of the bin the goods stand in is blocked, for the items on the held unit. Business Central stops picking from it and stops putting more into it. Anything else standing in that bin is blocked too, which is the point on a quarantine bin and a nuisance on a mixed one.';

    /// <summary>
    /// Blocks movement on the bin content the held unit occupies.
    /// </summary>
    /// <remarks>
    /// `Bin Content."Block Movement"` is set to **All**, not just outbound: goods under investigation
    /// should not be added to either, or the quantity being questioned changes while somebody is
    /// questioning it.
    ///
    /// The block is per **item in that bin**, not per handling unit, because that is the grain Business
    /// Central blocks at. Two pallets of the same item in one bin therefore share one block, which is
    /// why lifting it asks whether any other hold still needs it.
    /// </remarks>
    /// <param name="QualityHold">The hold being placed.</param>
    /// <param name="HandlingUnit">The unit being held.</param>
    /// <returns>How many bin content rows were blocked.</returns>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    begin
        exit(SetBlock(HandlingUnit, true));
    end;

    /// <summary>
    /// Unblocks the bin content, unless another live hold still stands on the same bin.
    /// </summary>
    /// <param name="QualityHold">The hold being closed.</param>
    /// <param name="HandlingUnit">The unit that was held.</param>
    /// <returns>How many bin content rows were released.</returns>
    procedure Lift(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    var
        HoldStockMgt: Codeunit "WHA Hold Stock Mgt.";
    begin
        if HoldStockMgt.AnotherHoldStandsOnBin(QualityHold, HandlingUnit) then
            exit(0);
        exit(SetBlock(HandlingUnit, false));
    end;

    /// <summary>
    /// Describes in one line what this policy does to Business Central.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    local procedure SetBlock(var HandlingUnit: Record "WHA Handling Unit"; Blocked: Boolean): Integer
    var
        BinContent: Record "Bin Content";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        Changed: Integer;
    begin
        if (HandlingUnit."Location Code" = '') or (HandlingUnit."Bin Code" = '') then
            exit(0);

        HandlingUnitLine.SetLoadFields("Item No.", "Variant Code", "Unit of Measure Code");
        HandlingUnitLine.SetRange("Handling Unit No.", HandlingUnit."No.");
        if not HandlingUnitLine.FindSet() then
            exit(0);

        repeat
            if HandlingUnitLine."Item No." <> '' then begin
                BinContent.SetRange("Location Code", HandlingUnit."Location Code");
                BinContent.SetRange("Bin Code", HandlingUnit."Bin Code");
                BinContent.SetRange("Item No.", HandlingUnitLine."Item No.");
                BinContent.SetRange("Variant Code", HandlingUnitLine."Variant Code");
                if HandlingUnitLine."Unit of Measure Code" <> '' then
                    BinContent.SetRange("Unit of Measure Code", HandlingUnitLine."Unit of Measure Code")
                else
                    BinContent.SetRange("Unit of Measure Code");
                Changed += BlockFound(BinContent, Blocked);
            end;
        until HandlingUnitLine.Next() = 0;

        exit(Changed);
    end;

    local procedure BlockFound(var BinContent: Record "Bin Content"; Blocked: Boolean): Integer
    var
        Changed: Integer;
    begin
        if not BinContent.FindSet() then
            exit(0);

        repeat
            if Blocked then begin
                if BinContent."Block Movement" <> BinContent."Block Movement"::All then begin
                    BinContent."Block Movement" := BinContent."Block Movement"::All;
                    BinContent.Modify(true);
                    Changed += 1;
                end;
            end else
                if BinContent."Block Movement" = BinContent."Block Movement"::All then begin
                    BinContent."Block Movement" := BinContent."Block Movement"::" ";
                    BinContent.Modify(true);
                    Changed += 1;
                end;
        until BinContent.Next() = 0;

        exit(Changed);
    end;
}
