namespace WarehouseAdvanced.Posting;

using Microsoft.Inventory.Journal;

codeunit 50751 "WHA Jnl. Line Posting" implements "WHA IInvtPosting"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The change is written to an item journal and left there. Nothing reaches the item ledger until somebody opens the journal, looks at what the warehouse found, and posts it.';
        TemplateMissingErr: Label 'Choose the item journal template the lines should be written to before posting this way, or the warehouse has nowhere to put them.';
        BatchMissingErr: Label 'Choose the item journal batch the lines should be written to before posting this way, or the warehouse has nowhere to put them.';
        BatchGoneErr: Label 'Item journal batch %1 in template %2 does not exist, so the lines have nowhere to go.', Comment = '%1 = the journal batch name, %2 = the journal template name';

    /// <summary>
    /// Writes every line on the request into an item journal batch and posts nothing. The warehouse keeps
    /// its own record of what it found either way; what this decides is who presses post.
    /// </summary>
    /// <param name="PostingRequest">The lines to write. Each is marked with the journal line it became.</param>
    /// <returns>How many lines were written.</returns>
    procedure Post(var PostingRequest: Record "WHA Posting Request"): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        PostingMgt: Codeunit "WHA Posting Mgt.";
        LineNo: Integer;
        Written: Integer;
    begin
        PostingRequest.Reset();
        if not PostingRequest.FindSet() then
            exit(0);

        CheckBatch(PostingRequest);
        LineNo := NextLineNo(PostingRequest."Journal Template Name", PostingRequest."Journal Batch Name");

        repeat
            PostingMgt.BuildJournalLine(PostingRequest, ItemJournalLine, LineNo);
            ItemJournalLine.Insert(true);

            PostingRequest."Journal Line No." := LineNo;
            PostingRequest.Modify(false);
            LineNo += 10000;
            Written += 1;
        until PostingRequest.Next() = 0;

        exit(Written);
    end;

    /// <summary>
    /// Describes in one line what this way of posting does.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Answers whether this way of posting writes to the item ledger.
    /// </summary>
    /// <returns>False. A journal line is a proposal, not a posting.</returns>
    procedure WritesToLedger(): Boolean
    begin
        exit(false);
    end;

    local procedure CheckBatch(var PostingRequest: Record "WHA Posting Request")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        if PostingRequest."Journal Template Name" = '' then
            Error(TemplateMissingErr);
        if PostingRequest."Journal Batch Name" = '' then
            Error(BatchMissingErr);

        ItemJournalBatch.SetLoadFields(Name);
        if not ItemJournalBatch.Get(PostingRequest."Journal Template Name", PostingRequest."Journal Batch Name") then
            Error(BatchGoneErr, PostingRequest."Journal Batch Name", PostingRequest."Journal Template Name");
    end;

    local procedure NextLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetLoadFields("Line No.");
        ItemJournalLine.SetRange("Journal Template Name", TemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", BatchName);
        if not ItemJournalLine.FindLast() then
            exit(10000);
        exit(ItemJournalLine."Line No." + 10000);
    end;
}
