namespace WarehouseAdvanced.Test;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using System.TestLibraries.Utilities;
using WarehouseAdvanced.Posting;

codeunit 59021 "WHA Posting Integration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LotMissingTxt: Label 'Item %1 is tracked by lot, so it cannot be posted without one.', Locked = true;

    [Test]
    procedure PostingDirectPutsStockIntoTheLedger()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] An item and a location that keeps no bins
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] A request to add five
        AddRequest(TempPostingRequest, 1, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 5);

        // [WHEN] It is posted straight to the ledger
        // [THEN] One line was posted and marked so
        Assert.AreEqual(1, PostingMgt.Post(Method::WHAPostDirect, TempPostingRequest), 'One line should have been posted.');
        TempPostingRequest.FindFirst();
        Assert.IsTrue(TempPostingRequest.Posted, 'A posted line is marked posted.');

        // [THEN] The ledger holds a positive adjustment of five at the location, under the document number
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        Assert.AreEqual(1, ItemLedgerEntry.Count(), 'One ledger entry should exist.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemLedgerEntry."Entry Type", 'Adding stock is a positive adjustment.');
        Assert.AreEqual(5, ItemLedgerEntry.Quantity, 'Five went in.');
        Assert.AreEqual('WHA-POST-1', ItemLedgerEntry."Document No.", 'The entry carries the document number it was asked for.');
    end;

    [Test]
    procedure PostingDirectTakesStockOutOfTheLedger()
    var
        Item: Record Item;
        Location: Record Location;
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] Eight of an item at a location
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        AddRequest(TempPostingRequest, 1, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 8);
        PostingMgt.Post(Method::WHAPostDirect, TempPostingRequest);

        // [GIVEN] A request to take three away
        TempPostingRequest.DeleteAll();
        AddRequest(TempPostingRequest, 1, TempPostingRequest."Posting Type"::WHANegativeAdjustment, Item."No.", Location.Code, 3);

        // [WHEN] It is posted straight to the ledger
        PostingMgt.Post(Method::WHAPostDirect, TempPostingRequest);

        // [THEN] Five are left at the location
        Item.SetRange("Location Filter", Location.Code);
        Item.CalcFields(Inventory);
        Assert.AreEqual(5, Item.Inventory, 'Eight in and three out leaves five.');
    end;

    [Test]
    procedure EveryLineOfARequestIsPosted()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] A request with three lines
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        AddRequest(TempPostingRequest, 1, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 1);
        AddRequest(TempPostingRequest, 2, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 2);
        AddRequest(TempPostingRequest, 3, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 4);

        // [WHEN] It is posted
        // [THEN] All three are posted, each as its own entry
        Assert.AreEqual(3, PostingMgt.Post(Method::WHAPostDirect, TempPostingRequest), 'Every line should be posted.');
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        Assert.AreEqual(3, ItemLedgerEntry.Count(), 'Each line is its own ledger entry.');
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(7, ItemLedgerEntry.Quantity, 'One, two and four make seven.');
    end;

    [Test]
    procedure JournalLinesAreWrittenAndLeftForSomebodyToPost()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ReasonCode: Record "Reason Code";
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] An item, a location, an empty item journal batch and a reason code
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateBatch(ItemJournalTemplate, ItemJournalBatch);
        EnsureReasonCode(ReasonCode);

        // [GIVEN] A request with a positive and a negative line for that batch
        AddRequest(TempPostingRequest, 1, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 6);
        AddRequest(TempPostingRequest, 2, TempPostingRequest."Posting Type"::WHANegativeAdjustment, Item."No.", Location.Code, 2);
        TempPostingRequest.ModifyAll("Journal Template Name", ItemJournalTemplate.Name);
        TempPostingRequest.ModifyAll("Journal Batch Name", ItemJournalBatch.Name);
        TempPostingRequest.ModifyAll("Reason Code", ReasonCode.Code);
        TempPostingRequest.ModifyAll(Description, 'Counted at the bench');

        // [WHEN] It is written as journal lines
        // [THEN] Both lines were written and nothing reached the ledger
        Assert.AreEqual(2, PostingMgt.Post(Method::WHAJournalLines, TempPostingRequest), 'Both lines should be written.');
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        Assert.IsTrue(ItemLedgerEntry.IsEmpty(), 'Journal lines wait for somebody to post them.');

        // [THEN] The lines carry the entry type, quantity, reason and description, numbered in tens of thousands
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        Assert.AreEqual(2, ItemJournalLine.Count(), 'Two lines are in the batch.');
        ItemJournalLine.FindFirst();
        Assert.AreEqual(10000, ItemJournalLine."Line No.", 'The first line in an empty batch is 10000.');
        Assert.AreEqual(ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type", 'The first line adds stock.');
        Assert.AreEqual(6, ItemJournalLine.Quantity, 'The first line is for six.');
        Assert.AreEqual(Location.Code, ItemJournalLine."Location Code", 'The line is at the location.');
        Assert.AreEqual(ReasonCode.Code, ItemJournalLine."Reason Code", 'The line carries the reason.');
        Assert.AreEqual('Counted at the bench', ItemJournalLine.Description, 'The line carries the description.');
        Assert.AreEqual('WHA-POST-1', ItemJournalLine."Document No.", 'The line carries the document number.');
        ItemJournalLine.FindLast();
        Assert.AreEqual(20000, ItemJournalLine."Line No.", 'The second line follows by 10000.');
        Assert.AreEqual(ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemJournalLine."Entry Type", 'The second line takes stock away.');

        // [THEN] Each request line remembers the journal line it became
        TempPostingRequest.FindFirst();
        Assert.AreEqual(10000, TempPostingRequest."Journal Line No.", 'The first request line points at line 10000.');
    end;

    [Test]
    procedure JournalLinesAreAddedAfterWhatIsAlreadyInTheBatch()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        Location: Record Location;
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] A batch that already holds a line somebody typed in, at line 30000
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateBatch(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := ItemJournalTemplate.Name;
        ItemJournalLine."Journal Batch Name" := ItemJournalBatch.Name;
        ItemJournalLine."Line No." := 30000;
        ItemJournalLine.Insert(false);

        // [WHEN] A request line is written to the same batch
        AddRequest(TempPostingRequest, 1, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 1);
        TempPostingRequest."Journal Template Name" := ItemJournalTemplate.Name;
        TempPostingRequest."Journal Batch Name" := ItemJournalBatch.Name;
        TempPostingRequest.Modify(false);
        PostingMgt.Post(Method::WHAJournalLines, TempPostingRequest);

        // [THEN] It goes after the existing line rather than over it
        TempPostingRequest.FindFirst();
        Assert.AreEqual(40000, TempPostingRequest."Journal Line No.", 'The new line follows what was already in the batch.');
        Assert.IsTrue(ItemJournalLine.Get(ItemJournalTemplate.Name, ItemJournalBatch.Name, 30000), 'The line somebody typed in is still there.');
    end;

    [Test]
    procedure ALotTrackedItemIsNotPostedWithoutALot()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [GIVEN] An item tracked by lot on every adjustment
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking" := true;
        ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking" := true;
        ItemTrackingCode.Modify(false);
        LibraryInventory.CreateItem(Item);
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify(false);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] A request to add some of it without saying which lot
        AddRequest(TempPostingRequest, 1, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 4);

        // [WHEN] It is posted straight to the ledger
        asserterror PostingMgt.Post(Method::WHAPostDirect, TempPostingRequest);

        // [THEN] It is refused before anything reaches the ledger
        Assert.ExpectedError(StrSubstNo(LotMissingTxt, Item."No."));
    end;

    [Test]
    procedure ALotTrackedItemCanStillBeWrittenToAJournalWithoutALot()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        TempPostingRequest: Record "WHA Posting Request" temporary;
        PostingMgt: Codeunit "WHA Posting Mgt.";
        Method: Enum "WHA Posting Method";
    begin
        // [SCENARIO] A journal line is reviewed by a person before it is posted, who can still give it a
        // lot, so only the methods that write to the ledger insist on one.
        // [GIVEN] A lot-tracked item and a journal batch
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking" := true;
        ItemTrackingCode.Modify(false);
        LibraryInventory.CreateItem(Item);
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify(false);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateBatch(ItemJournalTemplate, ItemJournalBatch);

        // [WHEN] A request without a lot is written to the journal
        AddRequest(TempPostingRequest, 1, TempPostingRequest."Posting Type"::WHAPositiveAdjustment, Item."No.", Location.Code, 4);
        TempPostingRequest."Journal Template Name" := ItemJournalTemplate.Name;
        TempPostingRequest."Journal Batch Name" := ItemJournalBatch.Name;
        TempPostingRequest.Modify(false);

        // [THEN] The line is written
        Assert.AreEqual(1, PostingMgt.Post(Method::WHAJournalLines, TempPostingRequest), 'The journal takes the line without a lot.');
    end;

    local procedure AddRequest(var TempPostingRequest: Record "WHA Posting Request" temporary; EntryNo: Integer; PostingType: Enum "WHA Posting Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        TempPostingRequest.Init();
        TempPostingRequest."Entry No." := EntryNo;
        TempPostingRequest."Posting Type" := PostingType;
        TempPostingRequest."Item No." := ItemNo;
        TempPostingRequest."Location Code" := LocationCode;
        TempPostingRequest.Quantity := Quantity;
        TempPostingRequest."Posting Date" := WorkDate();
        TempPostingRequest."Document No." := 'WHA-POST-1';
        TempPostingRequest.Insert(false);
    end;

    local procedure CreateBatch(var ItemJournalTemplate: Record "Item Journal Template"; var ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure EnsureReasonCode(var ReasonCode: Record "Reason Code")
    begin
        if ReasonCode.Get('WHA-CNT') then
            exit;
        ReasonCode.Init();
        ReasonCode.Code := 'WHA-CNT';
        ReasonCode.Description := 'Warehouse count';
        ReasonCode.Insert(false);
    end;
}
