namespace WarehouseAdvanced.Posting;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;

codeunit 50752 "WHA Direct Posting" implements "WHA IInvtPosting"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The change is posted straight to the item ledger, and the bins are told at the same time. What Business Central believes is in stock changes the moment the count sheet is closed or the goods are scrapped.';

    /// <summary>
    /// Posts every line on the request to the item ledger. The journal line is never stored: it is built,
    /// posted and discarded, so there is nothing left in a batch for somebody to post a second time.
    ///
    /// At a location with directed put-away and pick the warehouse half is written first, because the
    /// item journal line carries no bin there and posting alone would move the ledger while leaving the
    /// bins where they were. Both halves are one operation: if the ledger refuses the line, the warehouse
    /// entry goes with it.
    /// </summary>
    /// <param name="PostingRequest">The lines to post. Each is marked as posted as it goes through.</param>
    /// <returns>How many lines were posted.</returns>
    procedure Post(var PostingRequest: Record "WHA Posting Request"): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Posted: Integer;
    begin
        PostingRequest.Reset();
        if not PostingRequest.FindSet() then
            exit(0);

        repeat
            PostingMgt.RegisterWarehouseChange(PostingRequest);
            PostingMgt.BuildJournalLine(PostingRequest, ItemJournalLine, PostingRequest."Entry No." * 10000);
            ItemJnlPostLine.RunWithCheck(ItemJournalLine);

            PostingRequest.Posted := true;
            PostingRequest.Modify(false);
            Posted += 1;
        until PostingRequest.Next() = 0;

        exit(Posted);
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
    /// <returns>True.</returns>
    procedure WritesToLedger(): Boolean
    begin
        exit(true);
    end;
}
