namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Posting;

codeunit 50507 "WHA Count Posting"
{
    Access = Public;

    var
        LineDescriptionLbl: Label 'Count %1', Comment = '%1 = the count sheet number';

    /// <summary>
    /// Hands every difference on a counted sheet to the posting method chosen in the counting setup, and
    /// records what came back. Closing a sheet is the moment a difference stops being an observation and
    /// starts being an adjustment, which is why this runs there and nowhere else.
    /// </summary>
    /// <param name="CountSheet">The sheet being closed. Stamped with what the posting method did, but not modified.</param>
    /// <returns>How many lines the posting method took.</returns>
    internal procedure PostDifferences(var CountSheet: Record "WHA Count Sheet"): Integer
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        Setup: Record "WHA Count Setup";
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Taken: Integer;
    begin
        if BuildRequest(CountSheet, TempPostingRequest) = 0 then
            exit(0);

        ReadSetup(Setup);
        Taken := PostingMgt.Post(Setup."Posting Method", TempPostingRequest);
        if Taken = 0 then
            exit(0);

        WriteBack(CountSheet, TempPostingRequest);

        CountSheet.Posted := PostingMgt.WritesToLedger(Setup."Posting Method");
        CountSheet."Posting Document No." := CountSheet."No.";
        CountSheet."Posted At" := CurrentDateTime;

        exit(Taken);
    end;

    /// <summary>
    /// Turns the differences on a sheet into posting request lines, without posting anything. Kept apart
    /// from the posting itself so what a sheet would adjust can be asserted without a ledger to adjust.
    /// </summary>
    /// <param name="CountSheet">The sheet to read.</param>
    /// <param name="PostingRequest">Receives one line per difference. Not cleared first.</param>
    /// <returns>How many lines were added.</returns>
    internal procedure BuildRequest(var CountSheet: Record "WHA Count Sheet"; var PostingRequest: Record "WHA Posting Request"): Integer
    var
        CountSheetLine: Record "WHA Count Sheet Line";
        Setup: Record "WHA Count Setup";
        Added: Integer;
    begin
        CountSheetLine.SetCurrentKey("Sheet No.", Variance);
        CountSheetLine.SetRange("Sheet No.", CountSheet."No.");
        CountSheetLine.SetFilter(Variance, '<>%1', 0);
        if not CountSheetLine.FindSet() then
            exit(0);

        ReadSetup(Setup);
        repeat
            AddRequestLine(CountSheet, CountSheetLine, Setup, PostingRequest);
            Added += 1;
        until CountSheetLine.Next() = 0;

        exit(Added);
    end;

    local procedure AddRequestLine(var CountSheet: Record "WHA Count Sheet"; var CountSheetLine: Record "WHA Count Sheet Line"; var Setup: Record "WHA Count Setup"; var PostingRequest: Record "WHA Posting Request")
    var
        PostingMgt: Codeunit "WHA Posting Mgt.";
        NewEntryNo: Integer;
    begin
        NewEntryNo := PostingMgt.NextEntryNo(PostingRequest);

        PostingRequest.Init();
        PostingRequest."Entry No." := NewEntryNo;
        PostingRequest."Posting Type" := PostingTypeOf(CountSheetLine.Variance);
        PostingRequest."Item No." := CountSheetLine."Item No.";
        PostingRequest."Variant Code" := CountSheetLine."Variant Code";
        PostingRequest."Unit of Measure Code" := CountSheetLine."Unit of Measure Code";
        PostingRequest.Quantity := Abs(CountSheetLine.Variance);
        PostingRequest."Location Code" := CountSheet."Location Code";
        PostingRequest."Bin Code" := CountSheetLine."Bin Code";
        PostingRequest."Lot No." := CountSheetLine."Lot No.";
        PostingRequest."Serial No." := CountSheetLine."Serial No.";
        PostingRequest."Posting Date" := CountSheet."Posting Date";
        PostingRequest."Document No." := CountSheet."No.";
        PostingRequest.Description := CopyStr(StrSubstNo(LineDescriptionLbl, CountSheet."No."), 1, MaxStrLen(PostingRequest.Description));
        PostingRequest."Reason Code" := Setup."Posting Reason Code";
        PostingRequest."Journal Template Name" := Setup."Item Journal Template Name";
        PostingRequest."Journal Batch Name" := Setup."Item Journal Batch Name";
        PostingRequest."Source Table No." := Database::"WHA Count Sheet Line";
        PostingRequest."Source No." := CountSheetLine."Sheet No.";
        PostingRequest."Source Line No." := CountSheetLine."Line No.";
        PostingRequest.Insert(false);
    end;

    local procedure WriteBack(var CountSheet: Record "WHA Count Sheet"; var PostingRequest: Record "WHA Posting Request")
    var
        CountSheetLine: Record "WHA Count Sheet Line";
    begin
        PostingRequest.Reset();
        if not PostingRequest.FindSet() then
            exit;

        repeat
            if CountSheetLine.Get(CountSheet."No.", PostingRequest."Source Line No.") then begin
                CountSheetLine."Posting Quantity" := SignedQuantity(PostingRequest);
                CountSheetLine.Posted := PostingRequest.Posted;
                CountSheetLine.Modify(false);
            end;
        until PostingRequest.Next() = 0;
    end;

    local procedure ReadSetup(var Setup: Record "WHA Count Setup")
    begin
        Setup.SetLoadFields("Posting Method", "Item Journal Template Name", "Item Journal Batch Name", "Posting Reason Code");
        if Setup.Get() then
            exit;
        Setup.Init();
    end;

    local procedure PostingTypeOf(Variance: Decimal): Enum "WHA Posting Type"
    var
        PostingType: Enum "WHA Posting Type";
    begin
        if Variance < 0 then
            exit(PostingType::WHANegativeAdjustment);
        exit(PostingType::WHAPositiveAdjustment);
    end;

    local procedure SignedQuantity(var PostingRequest: Record "WHA Posting Request"): Decimal
    begin
        if PostingRequest."Posting Type" = PostingRequest."Posting Type"::WHANegativeAdjustment then
            exit(-PostingRequest.Quantity);
        exit(PostingRequest.Quantity);
    end;
}
