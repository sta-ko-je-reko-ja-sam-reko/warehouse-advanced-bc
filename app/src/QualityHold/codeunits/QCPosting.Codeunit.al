namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Posting;

codeunit 50559 "WHA QC Posting"
{
    Access = Public;

    var
        DocumentNoTok: Label 'QH%1', Locked = true;
        LineDescriptionLbl: Label 'Scrapped %1', Comment = '%1 = the handling unit number';

    /// <summary>
    /// Hands what a scrapped handling unit was holding to the posting method chosen in the quality hold
    /// setup, and records what came back on the hold. Does nothing for a decision that leaves the goods in
    /// stock, so it is safe to call on every release.
    /// </summary>
    /// <param name="QualityHold">The hold being released. Stamped with what the posting method did, but not modified.</param>
    /// <param name="Disposition">The decision being carried out.</param>
    /// <returns>How many lines the posting method took.</returns>
    internal procedure PostWriteOff(var QualityHold: Record "WHA Quality Hold"; Disposition: Enum "WHA Hold Disposition"): Integer
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        Setup: Record "WHA Quality Hold Setup";
        PostingMgt: Codeunit "WHA Posting Mgt.";
        HoldDisposition: Interface "WHA IHoldDisposition";
        Taken: Integer;
    begin
        HoldDisposition := Disposition;
        if not HoldDisposition.WritesOffStock() then
            exit(0);

        if BuildRequest(QualityHold, TempPostingRequest) = 0 then
            exit(0);

        ReadSetup(Setup);
        Taken := PostingMgt.Post(Setup."Posting Method", TempPostingRequest);
        if Taken = 0 then
            exit(0);

        QualityHold.Posted := PostingMgt.WritesToLedger(Setup."Posting Method");
        QualityHold."Posting Document No." := DocumentNo(QualityHold);
        QualityHold."Posted At" := CurrentDateTime;
        QualityHold."Posted Quantity" := TotalQuantity(TempPostingRequest);

        exit(Taken);
    end;

    /// <summary>
    /// Turns what the held handling unit is carrying into posting request lines, without posting anything.
    /// Only the unit's own contents are taken: a unit nested inside it carries its own hold and writes
    /// itself off, so nothing is counted twice.
    /// </summary>
    /// <param name="QualityHold">The hold to read.</param>
    /// <param name="PostingRequest">Receives one line per thing the unit holds. Not cleared first.</param>
    /// <returns>How many lines were added.</returns>
    internal procedure BuildRequest(var QualityHold: Record "WHA Quality Hold"; var PostingRequest: Record "WHA Posting Request"): Integer
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
        Setup: Record "WHA Quality Hold Setup";
        Added: Integer;
    begin
        HandlingUnit.SetLoadFields("Location Code", "Bin Code");
        if not HandlingUnit.Get(QualityHold."Handling Unit No.") then
            exit(0);

        HandlingUnitLine.SetLoadFields("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Lot No.", "Serial No.");
        HandlingUnitLine.SetRange("Handling Unit No.", QualityHold."Handling Unit No.");
        HandlingUnitLine.SetFilter(Quantity, '>%1', 0);
        if not HandlingUnitLine.FindSet() then
            exit(0);

        ReadSetup(Setup);
        repeat
            AddRequestLine(QualityHold, HandlingUnit, HandlingUnitLine, Setup, PostingRequest);
            Added += 1;
        until HandlingUnitLine.Next() = 0;

        exit(Added);
    end;

    local procedure AddRequestLine(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit"; var HandlingUnitLine: Record "WHA Handling Unit Line"; var Setup: Record "WHA Quality Hold Setup"; var PostingRequest: Record "WHA Posting Request")
    var
        PostingMgt: Codeunit "WHA Posting Mgt.";
        NewEntryNo: Integer;
    begin
        NewEntryNo := PostingMgt.NextEntryNo(PostingRequest);

        PostingRequest.Init();
        PostingRequest."Entry No." := NewEntryNo;
        PostingRequest."Posting Type" := PostingRequest."Posting Type"::WHANegativeAdjustment;
        PostingRequest."Item No." := HandlingUnitLine."Item No.";
        PostingRequest."Variant Code" := HandlingUnitLine."Variant Code";
        PostingRequest."Unit of Measure Code" := HandlingUnitLine."Unit of Measure Code";
        PostingRequest.Quantity := HandlingUnitLine.Quantity;
        PostingRequest."Location Code" := HandlingUnit."Location Code";
        PostingRequest."Bin Code" := HandlingUnit."Bin Code";
        PostingRequest."Lot No." := HandlingUnitLine."Lot No.";
        PostingRequest."Serial No." := HandlingUnitLine."Serial No.";
        PostingRequest."Posting Date" := WorkDate();
        PostingRequest."Document No." := DocumentNo(QualityHold);
        PostingRequest.Description := CopyStr(StrSubstNo(LineDescriptionLbl, QualityHold."Handling Unit No."), 1, MaxStrLen(PostingRequest.Description));
        PostingRequest."Reason Code" := Setup."Posting Reason Code";
        PostingRequest."Journal Template Name" := Setup."Item Journal Template Name";
        PostingRequest."Journal Batch Name" := Setup."Item Journal Batch Name";
        PostingRequest."Source Table No." := Database::"WHA Quality Hold";
        PostingRequest."Source No." := CopyStr(Format(QualityHold."Entry No."), 1, MaxStrLen(PostingRequest."Source No."));
        PostingRequest."Source Line No." := HandlingUnitLine."Line No.";
        PostingRequest.Insert(false);
    end;

    local procedure TotalQuantity(var PostingRequest: Record "WHA Posting Request"): Decimal
    var
        Total: Decimal;
    begin
        PostingRequest.Reset();
        if not PostingRequest.FindSet() then
            exit(0);

        repeat
            Total += PostingRequest.Quantity;
        until PostingRequest.Next() = 0;

        exit(Total);
    end;

    local procedure ReadSetup(var Setup: Record "WHA Quality Hold Setup")
    begin
        Setup.SetLoadFields("Posting Method", "Item Journal Template Name", "Item Journal Batch Name", "Posting Reason Code");
        if Setup.Get() then
            exit;
        Setup.Init();
    end;

    local procedure DocumentNo(var QualityHold: Record "WHA Quality Hold"): Code[20]
    begin
        exit(CopyStr(StrSubstNo(DocumentNoTok, QualityHold."Entry No."), 1, 20));
    end;
}
