namespace WarehouseAdvanced.Test;

using Microsoft.Inventory.Journal;
using System.TestLibraries.Utilities;
using WarehouseAdvanced.Posting;

codeunit 59020 "WHA Posting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure OnlyPostingToTheLedgerWritesToTheLedger()
    var
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [SCENARIO] Tracking is only checked for a method that writes to the ledger, so this answer
        // decides whether a lot-tracked item can be counted without a lot.
        // [WHEN] Each built-in method is asked whether it writes to the item ledger
        // [THEN] Only posting to the ledger says yes
        Assert.IsFalse(PostingMgt.WritesToLedger(Method::WHANone), 'Not posting writes nothing.');
        Assert.IsFalse(PostingMgt.WritesToLedger(Method::WHAJournalLines), 'Journal lines wait for somebody to post them.');
        Assert.IsTrue(PostingMgt.WritesToLedger(Method::WHAPostDirect), 'Posting to the ledger writes to the ledger.');
    end;

    [Test]
    procedure EveryPostingMethodExplainsItself()
    var
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [SCENARIO] The setup pages show what each method does, so a user can choose without guessing.
        // [THEN] Each built-in method has its own description
        Assert.AreNotEqual('', PostingMgt.Describe(Method::WHANone), 'Not posting should explain itself.');
        Assert.AreNotEqual('', PostingMgt.Describe(Method::WHAJournalLines), 'Journal lines should explain themselves.');
        Assert.AreNotEqual('', PostingMgt.Describe(Method::WHAPostDirect), 'Posting to the ledger should explain itself.');
        Assert.AreNotEqual(PostingMgt.Describe(Method::WHAJournalLines), PostingMgt.Describe(Method::WHAPostDirect), 'Two methods should not share a description.');
    end;

    [Test]
    procedure NotPostingTakesNoLine()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] A request with a line on it
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 5);

        // [WHEN] It is handed to the method that does not post
        // [THEN] No line is taken and the line is not marked posted
        Assert.AreEqual(0, PostingMgt.Post(Method::WHANone, TempPostingRequest), 'Not posting takes no line.');
        TempPostingRequest.FindFirst();
        Assert.IsFalse(TempPostingRequest.Posted, 'A line nobody posted is not marked posted.');
    end;

    [Test]
    procedure AnEmptyRequestPostsNothingWhateverTheMethod()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] A request with no lines
        // [WHEN] It is handed to each method
        // [THEN] Each takes nothing and none complains about a missing journal
        Assert.AreEqual(0, PostingMgt.Post(Method::WHANone, TempPostingRequest), 'Nothing to post under None.');
        Assert.AreEqual(0, PostingMgt.Post(Method::WHAJournalLines, TempPostingRequest), 'Nothing to write under Journal Lines.');
        Assert.AreEqual(0, PostingMgt.Post(Method::WHAPostDirect, TempPostingRequest), 'Nothing to post under Post Direct.');
    end;

    [Test]
    procedure JournalLinesNeedATemplate()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] A request line that names no journal template
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 5);

        // [WHEN] It is written to a journal
        asserterror PostingMgt.Post(Method::WHAJournalLines, TempPostingRequest);

        // [THEN] The template is asked for
        Assert.ExpectedError('Choose the item journal template the lines should be written to');
    end;

    [Test]
    procedure JournalLinesNeedABatch()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] A request line with a template and no batch
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 5);
        TempPostingRequest."Journal Template Name" := 'WHA-TMPL';
        TempPostingRequest.Modify(false);

        // [WHEN] It is written to a journal
        asserterror PostingMgt.Post(Method::WHAJournalLines, TempPostingRequest);

        // [THEN] The batch is asked for
        Assert.ExpectedError('Choose the item journal batch the lines should be written to');
    end;

    [Test]
    procedure JournalLinesNeedABatchThatExists()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] A request line naming a batch that is not there
        if ItemJournalBatch.Get('WHA-GONE', 'WHA-GONE') then
            ItemJournalBatch.Delete(false);
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 5);
        TempPostingRequest."Journal Template Name" := 'WHA-GONE';
        TempPostingRequest."Journal Batch Name" := 'WHA-GONE';
        TempPostingRequest.Modify(false);

        // [WHEN] It is written to a journal
        asserterror PostingMgt.Post(Method::WHAJournalLines, TempPostingRequest);

        // [THEN] The missing batch is named
        Assert.ExpectedError('Item journal batch WHA-GONE in template WHA-GONE does not exist');
    end;

    [Test]
    procedure ALineWithoutAnItemIsRefused()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        ItemJournalLine: Record "Item Journal Line";
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        // [GIVEN] A request line with no item
        AddRequest(TempPostingRequest, 1, '', 5);

        // [WHEN] A journal line is built from it
        asserterror PostingMgt.BuildJournalLine(TempPostingRequest, ItemJournalLine, 10000);

        // [THEN] It is refused before anything is validated
        Assert.ExpectedError('A posting request line has no item on it');
    end;

    [Test]
    procedure ALineWithoutAQuantityIsRefused()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        ItemJournalLine: Record "Item Journal Line";
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        // [GIVEN] A request line for nothing
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 0);

        // [WHEN] A journal line is built from it
        asserterror PostingMgt.BuildJournalLine(TempPostingRequest, ItemJournalLine, 10000);

        // [THEN] It is refused, naming the item
        Assert.ExpectedError('The posting request for item WHA-NO-ITEM has no quantity on it');
    end;

    [Test]
    procedure ALineWithoutAPostingDateIsRefused()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        ItemJournalLine: Record "Item Journal Line";
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        // [GIVEN] A request line with no posting date
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 5);
        TempPostingRequest."Posting Date" := 0D;
        TempPostingRequest.Modify(false);

        // [WHEN] A journal line is built from it
        asserterror PostingMgt.BuildJournalLine(TempPostingRequest, ItemJournalLine, 10000);

        // [THEN] It is refused
        Assert.ExpectedError('The posting request for item WHA-NO-ITEM has no posting date on it.');
    end;

    [Test]
    procedure ALineWithoutADocumentNoIsRefused()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        ItemJournalLine: Record "Item Journal Line";
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        // [SCENARIO] A ledger entry nobody can trace back to its cause is worse than no entry.
        // [GIVEN] A request line with no document number
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 5);
        TempPostingRequest."Document No." := '';
        TempPostingRequest.Modify(false);

        // [WHEN] A journal line is built from it
        asserterror PostingMgt.BuildJournalLine(TempPostingRequest, ItemJournalLine, 10000);

        // [THEN] It is refused
        Assert.ExpectedError('has no document number on it');
    end;

    [Test]
    procedure ASerialNumberNamesOneUnit()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        // [GIVEN] A request line for two of one serial number
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 2);
        TempPostingRequest."Serial No." := 'SN-001';
        TempPostingRequest.Modify(false);

        // [WHEN] Its tracking is checked
        asserterror PostingMgt.CheckTracking(TempPostingRequest);

        // [THEN] It is refused, because a serial number is one unit
        Assert.ExpectedError('Serial number SN-001 of item WHA-NO-ITEM names one unit');
    end;

    [Test]
    procedure AnItemNobodyKnowsNeedsNoTracking()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        // [GIVEN] A request line for an item that has no record, and so no tracking code
        AddRequest(TempPostingRequest, 1, 'WHA-NO-ITEM', 3);

        // [WHEN] Its tracking is checked
        PostingMgt.CheckTracking(TempPostingRequest);

        // [THEN] Nothing is raised; the ledger itself will refuse an item that does not exist
        Assert.AreEqual(1, TempPostingRequest.Count(), 'The request is left as it was.');
    end;

    [Test]
    procedure EntryNumbersFollowOnFromTheLast()
    var
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        // [GIVEN] An empty request
        // [THEN] The first line is number one
        Assert.AreEqual(1, PostingMgt.NextEntryNo(TempPostingRequest), 'The first line is number one.');

        // [GIVEN] A request whose last line is number seven
        AddRequest(TempPostingRequest, 7, 'WHA-NO-ITEM', 1);
        // [THEN] The next line is number eight
        Assert.AreEqual(8, PostingMgt.NextEntryNo(TempPostingRequest), 'The next line follows the last.');
    end;

    local procedure AddRequest(var TempPostingRequest: Record "WHA Posting Request" temporary; EntryNo: Integer; ItemNo: Code[20]; Quantity: Decimal)
    begin
        TempPostingRequest.Init();
        TempPostingRequest."Entry No." := EntryNo;
        TempPostingRequest."Posting Type" := TempPostingRequest."Posting Type"::WHAPositiveAdjustment;
        TempPostingRequest."Item No." := ItemNo;
        TempPostingRequest.Quantity := Quantity;
        TempPostingRequest."Posting Date" := WorkDate();
        TempPostingRequest."Document No." := 'WHA-POST-1';
        TempPostingRequest.Insert(false);
    end;
}
