namespace WarehouseAdvanced.Posting;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using WarehouseAdvanced.Registration;

codeunit 50753 "WHA Posting Mgt."
{
    Access = Public;

    var
        ItemMissingErr: Label 'A posting request line has no item on it, so there is nothing to post.';
        QuantityMissingErr: Label 'The posting request for item %1 has no quantity on it, so there is nothing to post.', Comment = '%1 = the item number';
        PostingDateMissingErr: Label 'The posting request for item %1 has no posting date on it.', Comment = '%1 = the item number';
        DocumentNoMissingErr: Label 'The posting request for item %1 has no document number on it, so the ledger entry could not be traced back to what caused it.', Comment = '%1 = the item number';

    /// <summary>
    /// Hands the request to the chosen way of posting. This is the single place a feature calls, so a
    /// feature never learns what any implementation does with what it is given.
    /// </summary>
    /// <param name="Method">The way of posting chosen in the calling feature's setup.</param>
    /// <param name="PostingRequest">The lines to post. Marked up in place with what happened to each.</param>
    /// <returns>How many lines the implementation took.</returns>
    internal procedure Post(Method: Enum "WHA Posting Method"; var PostingRequest: Record "WHA Posting Request"): Integer
    var
        InvtPosting: Interface "WHA IInvtPosting";
    begin
        InvtPosting := Method;
        exit(InvtPosting.Post(PostingRequest));
    end;

    /// <summary>
    /// Answers whether the chosen way of posting writes to the item ledger.
    /// </summary>
    /// <param name="Method">The way of posting chosen in the calling feature's setup.</param>
    /// <returns>True when running it changes what Business Central believes is in stock.</returns>
    internal procedure WritesToLedger(Method: Enum "WHA Posting Method"): Boolean
    var
        InvtPosting: Interface "WHA IInvtPosting";
    begin
        InvtPosting := Method;
        exit(InvtPosting.WritesToLedger());
    end;

    /// <summary>
    /// Describes in one line what the chosen way of posting does.
    /// </summary>
    /// <param name="Method">The way of posting chosen in the calling feature's setup.</param>
    /// <returns>A short description in the user's language.</returns>
    internal procedure Describe(Method: Enum "WHA Posting Method"): Text
    var
        InvtPosting: Interface "WHA IInvtPosting";
    begin
        InvtPosting := Method;
        exit(InvtPosting.Describe());
    end;

    /// <summary>
    /// Tells the warehouse what a posting is about to do to the bins, where Business Central keeps bins
    /// that an item journal line cannot reach. At a location with directed put-away and pick, the item
    /// journal line carries no bin at all — bins live in warehouse entries alone — so posting the ledger
    /// without this leaves the two halves of the same adjustment describing different warehouses.
    /// </summary>
    /// <remarks>
    /// The change is registered directly rather than through the method enum on
    /// <see cref="WHA Whse. Reg. Mgt."/>, and that is deliberate: once a feature has decided to write to
    /// the ledger, telling the warehouse is not a second choice somebody could switch off. It is the rest
    /// of the same operation, and half of it is worse than neither half.
    ///
    /// Nothing is registered against the location's **adjustment bin**. Business Central uses that bin to
    /// hold the difference between a warehouse that has been adjusted and a ledger that has not, and
    /// *Calculate Whse. Adjustment* turns whatever stands in it into item journal lines. Because both
    /// halves are written here, that difference is zero, and leaving anything in the adjustment bin
    /// would be picked up later and posted a second time.
    /// </remarks>
    /// <param name="PostingRequest">The line about to be posted. Read, not modified.</param>
    /// <returns>True when a warehouse entry was written.</returns>
    internal procedure RegisterWarehouseChange(var PostingRequest: Record "WHA Posting Request"): Boolean
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
    begin
        if PostingRequest."Bin Code" = '' then
            exit(false);
        if not WhseRegMgt.LocationIsDirected(PostingRequest."Location Code") then
            exit(false);

        BuildMoveRequest(PostingRequest, TempMoveRequest);
        exit(WhseRegMgt.RegisterAdjustment(TempMoveRequest) > 0);
    end;

    local procedure BuildMoveRequest(var PostingRequest: Record "WHA Posting Request"; var MoveRequest: Record "WHA Whse. Move Request")
    begin
        MoveRequest.Init();
        MoveRequest."Entry No." := 1;
        MoveRequest."Item No." := PostingRequest."Item No.";
        MoveRequest."Variant Code" := PostingRequest."Variant Code";
        MoveRequest."Unit of Measure Code" := PostingRequest."Unit of Measure Code";
        MoveRequest.Quantity := PostingRequest.Quantity;
        MoveRequest."Location Code" := PostingRequest."Location Code";
        MoveRequest."Lot No." := PostingRequest."Lot No.";
        MoveRequest."Serial No." := PostingRequest."Serial No.";
        MoveRequest."Registering Date" := PostingRequest."Posting Date";
        MoveRequest.Description := PostingRequest.Description;
        MoveRequest."Reference No." := PostingRequest."Document No.";
        MoveRequest."Source Table No." := PostingRequest."Source Table No.";
        MoveRequest."Source No." := PostingRequest."Source No.";

        if PostingRequest."Posting Type" = PostingRequest."Posting Type"::WHANegativeAdjustment then begin
            MoveRequest."Change Type" := MoveRequest."Change Type"::WHADecrease;
            MoveRequest."From Bin Code" := PostingRequest."Bin Code";
        end else begin
            MoveRequest."Change Type" := MoveRequest."Change Type"::WHAIncrease;
            MoveRequest."To Bin Code" := PostingRequest."Bin Code";
        end;

        MoveRequest.Insert(false);
    end;

    /// <summary>
    /// Answers the next free entry number on a request buffer, so a caller building one does not have to
    /// count its own lines. It reads the buffer, so it **repositions the record** — ask for the number
    /// before calling Init, not after, or the fields just initialised are overwritten.
    /// </summary>
    /// <param name="PostingRequest">The request buffer being built. Reset and repositioned by this call.</param>
    /// <returns>One more than the highest entry number on the buffer.</returns>
    internal procedure NextEntryNo(var PostingRequest: Record "WHA Posting Request"): Integer
    begin
        PostingRequest.Reset();
        if not PostingRequest.FindLast() then
            exit(1);
        exit(PostingRequest."Entry No." + 1);
    end;

    /// <summary>
    /// Turns one request line into an item journal line, without inserting or posting it. Both ways of
    /// posting that touch a journal build the line here, so the two cannot drift apart.
    /// </summary>
    /// <param name="PostingRequest">The request line to turn into a journal line.</param>
    /// <param name="ItemJournalLine">Receives the journal line.</param>
    /// <param name="LineNo">The line number to give it.</param>
    internal procedure BuildJournalLine(var PostingRequest: Record "WHA Posting Request"; var ItemJournalLine: Record "Item Journal Line"; LineNo: Integer)
    var
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
    begin
        CheckRequestLine(PostingRequest);

        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := PostingRequest."Journal Template Name";
        ItemJournalLine."Journal Batch Name" := PostingRequest."Journal Batch Name";
        ItemJournalLine."Line No." := LineNo;
        ItemJournalLine.Validate("Posting Date", PostingRequest."Posting Date");
        ItemJournalLine."Document No." := PostingRequest."Document No.";
        ItemJournalLine.Validate("Entry Type", EntryTypeOf(PostingRequest."Posting Type"));
        ItemJournalLine.Validate("Item No.", PostingRequest."Item No.");
        if PostingRequest."Variant Code" <> '' then
            ItemJournalLine.Validate("Variant Code", PostingRequest."Variant Code");
        ItemJournalLine.Validate("Location Code", PostingRequest."Location Code");
        if PostingRequest."Unit of Measure Code" <> '' then
            ItemJournalLine.Validate("Unit of Measure Code", PostingRequest."Unit of Measure Code");
        if WhseRegMgt.LocationIsDirected(PostingRequest."Location Code") then
            ItemJournalLine."Warehouse Adjustment" := true
        else
            if PostingRequest."Bin Code" <> '' then
                ItemJournalLine.Validate("Bin Code", PostingRequest."Bin Code");
        ItemJournalLine.Validate(Quantity, PostingRequest.Quantity);

        if PostingRequest.Description <> '' then
            ItemJournalLine.Description := PostingRequest.Description;
        ItemJournalLine."Reason Code" := PostingRequest."Reason Code";
        ItemJournalLine."Lot No." := PostingRequest."Lot No.";
        ItemJournalLine."Serial No." := PostingRequest."Serial No.";
    end;

    local procedure CheckRequestLine(var PostingRequest: Record "WHA Posting Request")
    begin
        if PostingRequest."Item No." = '' then
            Error(ItemMissingErr);
        if PostingRequest.Quantity <= 0 then
            Error(QuantityMissingErr, PostingRequest."Item No.");
        if PostingRequest."Posting Date" = 0D then
            Error(PostingDateMissingErr, PostingRequest."Item No.");
        if PostingRequest."Document No." = '' then
            Error(DocumentNoMissingErr, PostingRequest."Item No.");
    end;

    local procedure EntryTypeOf(PostingType: Enum "WHA Posting Type"): Enum "Item Ledger Entry Type"
    var
        EntryType: Enum "Item Ledger Entry Type";
    begin
        if PostingType = PostingType::WHANegativeAdjustment then
            exit(EntryType::"Negative Adjmt.");
        exit(EntryType::"Positive Adjmt.");
    end;
}
