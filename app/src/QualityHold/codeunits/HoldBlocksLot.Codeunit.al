namespace WarehouseAdvanced.QualityHold;

using Microsoft.Inventory.Tracking;
using WarehouseAdvanced.HandlingUnit;

codeunit 50563 "WHA Hold Blocks Lot" implements "WHA IHoldStockPolicy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The lot the goods belong to is blocked, wherever it is. Business Central refuses to post it anywhere, including stock of the same lot standing in other bins and other warehouses. That is what a recall wants and more than a single suspect pallet usually deserves.';

    /// <summary>
    /// Blocks every lot the held unit carries.
    /// </summary>
    /// <remarks>
    /// The block lives on `Lot No. Information`, and there may be no such record — Business Central
    /// creates them on demand. One is created here when it is missing, because a block written nowhere
    /// blocks nothing, and a lot this app has quarantined is exactly a lot somebody should be able to
    /// look up.
    ///
    /// **This reaches much further than the pallet.** A lot is not a location: blocking it stops the same
    /// lot in every bin and every warehouse in the company. It is the right answer to a recall and the
    /// wrong one to a single damaged pallet, which is why it is a choice and not the default.
    /// </remarks>
    /// <param name="QualityHold">The hold being placed.</param>
    /// <param name="HandlingUnit">The unit being held.</param>
    /// <returns>How many lots were blocked.</returns>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    begin
        exit(SetBlock(HandlingUnit, true, QualityHold));
    end;

    /// <summary>
    /// Unblocks each lot, unless another live hold still stands on it.
    /// </summary>
    /// <param name="QualityHold">The hold being closed.</param>
    /// <param name="HandlingUnit">The unit that was held.</param>
    /// <returns>How many lots were released.</returns>
    procedure Lift(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"): Integer
    begin
        exit(SetBlock(HandlingUnit, false, QualityHold));
    end;

    /// <summary>
    /// Describes in one line what this policy does to Business Central.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    local procedure SetBlock(var HandlingUnit: Record "WHA Handling Unit"; Blocked: Boolean; var QualityHold: Record "WHA Quality Hold"): Integer
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        HoldStockMgt: Codeunit "WHA Hold Stock Mgt.";
        Changed: Integer;
    begin
        HandlingUnitLine.SetLoadFields("Item No.", "Variant Code", "Lot No.");
        HandlingUnitLine.SetRange("Handling Unit No.", HandlingUnit."No.");
        HandlingUnitLine.SetFilter("Lot No.", '<>%1', '');
        if not HandlingUnitLine.FindSet() then
            exit(0);

        repeat
            if HandlingUnitLine."Item No." <> '' then
                if Blocked or not HoldStockMgt.AnotherHoldStandsOnLot(QualityHold, HandlingUnitLine."Item No.", HandlingUnitLine."Lot No.") then
                    Changed += BlockLot(HandlingUnitLine, Blocked);
        until HandlingUnitLine.Next() = 0;

        exit(Changed);
    end;

    local procedure BlockLot(var HandlingUnitLine: Record "WHA Handling Unit Line"; Blocked: Boolean): Integer
    var
        LotNoInformation: Record "Lot No. Information";
    begin
        if not LotNoInformation.Get(HandlingUnitLine."Item No.", HandlingUnitLine."Variant Code", HandlingUnitLine."Lot No.") then begin
            if not Blocked then
                exit(0);

            LotNoInformation.Init();
            LotNoInformation."Item No." := HandlingUnitLine."Item No.";
            LotNoInformation."Variant Code" := HandlingUnitLine."Variant Code";
            LotNoInformation."Lot No." := HandlingUnitLine."Lot No.";
            LotNoInformation.Blocked := true;
            LotNoInformation.Insert(true);
            exit(1);
        end;

        if LotNoInformation.Blocked = Blocked then
            exit(0);

        LotNoInformation.Blocked := Blocked;
        LotNoInformation.Modify(true);
        exit(1);
    end;
}
