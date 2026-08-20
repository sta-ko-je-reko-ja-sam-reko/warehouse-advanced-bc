namespace WarehouseAdvanced.Registration;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 50801 "WHA Whse. Jnl. Registration" implements "WHA IWhseRegistration"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Every finished job is registered as a warehouse movement. Business Central''s bin content and warehouse entries follow the floor, so the app and the ledger never hold two different pictures of the same shelf.';

    /// <summary>
    /// Registers everything on the request, through the same codeunit Business Central registers its own
    /// put-aways, picks and movements with. A change at a location that keeps no bins is skipped rather
    /// than refused: there is no bin-level record there for a warehouse entry to be true about, so the
    /// app recording it in its own records is the whole of it.
    /// </summary>
    /// <param name="MoveRequest">The changes to record. Each is marked as it goes through.</param>
    /// <returns>How many changes reached the warehouse entries.</returns>
    procedure Register(var MoveRequest: Record "WHA Whse. Move Request"): Integer
    var
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
        Registered: Integer;
    begin
        MoveRequest.Reset();
        if not MoveRequest.FindSet() then
            exit(0);

        repeat
            WhseRegMgt.CheckRequestLine(MoveRequest);
            if WhseRegMgt.LocationKeepsBins(MoveRequest."Location Code") then begin
                RegisterMove(MoveRequest);
                Registered += 1;
            end;
        until MoveRequest.Next() = 0;

        exit(Registered);
    end;

    /// <summary>
    /// Describes in one line what this way of recording a move does.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Answers whether this way of recording a move changes what Business Central believes is in each bin.
    /// </summary>
    /// <returns>True.</returns>
    procedure UpdatesBinContent(): Boolean
    begin
        exit(true);
    end;

    local procedure RegisterMove(var MoveRequest: Record "WHA Whse. Move Request")
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WMSMgt: Codeunit "WMS Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl;
    begin
        BuildJournalLine(MoveRequest, WarehouseJournalLine);
        if MoveRequest."Change Type" = MoveRequest."Change Type"::WHAMove then
            WMSMgt.CheckWhseJnlLine(WarehouseJournalLine, SourceJnl::WhseJnl, 0, false)
        else
            WMSMgt.CheckWhseJnlLine(WarehouseJournalLine, SourceJnl::ItemJnl, 0, false);
        WhseJnlRegisterLine.Run(WarehouseJournalLine);

        MoveRequest.Registered := true;
        MoveRequest."Warehouse Entry No." := WhseJnlRegisterLine.GetWhseEntryNo();
        MoveRequest.Modify(false);
    end;

    /// <summary>
    /// Turns one request line into a warehouse journal line, without checking or registering it. The
    /// shape is taken from what Business Central builds when it registers a movement of its own, so a
    /// warehouse entry this app writes is indistinguishable from one the base application wrote.
    /// </summary>
    /// <param name="MoveRequest">The request line to turn into a journal line.</param>
    /// <param name="WarehouseJournalLine">Receives the journal line.</param>
    internal procedure BuildJournalLine(var MoveRequest: Record "WHA Whse. Move Request"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        Item: Record Item;
        Location: Record Location;
        SourceCodeSetup: Record "Source Code Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
        WMSMgt: Codeunit "WMS Management";
        QtyPerUnitOfMeasure: Decimal;
        QuantityBase: Decimal;
    begin
        Location.SetLoadFields("Directed Put-away and Pick");
        Location.Get(MoveRequest."Location Code");

        Item.SetLoadFields("No.", "Base Unit of Measure");
        Item.Get(MoveRequest."Item No.");

        QtyPerUnitOfMeasure := 1;
        if MoveRequest."Unit of Measure Code" <> '' then
            QtyPerUnitOfMeasure := UOMMgt.GetQtyPerUnitOfMeasure(Item, MoveRequest."Unit of Measure Code");
        if QtyPerUnitOfMeasure = 0 then
            QtyPerUnitOfMeasure := 1;
        QuantityBase := MoveRequest.Quantity * QtyPerUnitOfMeasure;

        WarehouseJournalLine.Init();
        WarehouseJournalLine."Location Code" := MoveRequest."Location Code";
        WarehouseJournalLine."Item No." := MoveRequest."Item No.";
        WarehouseJournalLine."Variant Code" := MoveRequest."Variant Code";
        WarehouseJournalLine."Registering Date" := RegisteringDateOf(MoveRequest);
        WarehouseJournalLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(WarehouseJournalLine."User ID"));
        SetEntryTypeAndBins(MoveRequest, WarehouseJournalLine);
        WarehouseJournalLine.Description := MoveRequest.Description;

        if Location."Directed Put-away and Pick" then begin
            WarehouseJournalLine.Quantity := MoveRequest.Quantity;
            WarehouseJournalLine."Unit of Measure Code" := UnitOfMeasureOf(MoveRequest, Item);
            WarehouseJournalLine."Qty. per Unit of Measure" := QtyPerUnitOfMeasure;
        end else begin
            WarehouseJournalLine.Quantity := QuantityBase;
            WarehouseJournalLine."Unit of Measure Code" := WMSMgt.GetBaseUOM(MoveRequest."Item No.");
            WarehouseJournalLine."Qty. per Unit of Measure" := 1;
        end;
        WarehouseJournalLine."Qty. (Base)" := QuantityBase;
        WarehouseJournalLine."Qty. (Absolute)" := WarehouseJournalLine.Quantity;
        WarehouseJournalLine."Qty. (Absolute, Base)" := QuantityBase;

        SourceCodeSetup.SetLoadFields("Whse. Movement", "Item Journal");
        if SourceCodeSetup.Get() then
            if MoveRequest."Change Type" = MoveRequest."Change Type"::WHAMove then
                WarehouseJournalLine."Source Code" := SourceCodeSetup."Whse. Movement"
            else
                WarehouseJournalLine."Source Code" := SourceCodeSetup."Item Journal";
        WarehouseJournalLine."Reference Document" := ReferenceDocumentOf(MoveRequest);
        WarehouseJournalLine."Reference No." := MoveRequest."Reference No.";

        WarehouseJournalLine."Lot No." := MoveRequest."Lot No.";
        WarehouseJournalLine."Serial No." := MoveRequest."Serial No.";
        WarehouseJournalLine."New Lot No." := MoveRequest."Lot No.";
        WarehouseJournalLine."New Serial No." := MoveRequest."Serial No.";

        SetExpirationDate(MoveRequest, WarehouseJournalLine);
    end;

    local procedure SetExpirationDate(var MoveRequest: Record "WHA Whse. Move Request"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
        ExpirationDate: Date;
    begin
        if not WhseRegMgt.KnownWarehouseExpiry(
            MoveRequest."Item No.", MoveRequest."Variant Code", MoveRequest."Location Code",
            MoveRequest."Lot No.", MoveRequest."Serial No.", ExpirationDate)
        then
            exit;

        WarehouseJournalLine."Expiration Date" := ExpirationDate;
        WarehouseJournalLine."New Expiration Date" := ExpirationDate;
    end;

    local procedure SetEntryTypeAndBins(var MoveRequest: Record "WHA Whse. Move Request"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        case MoveRequest."Change Type" of
            MoveRequest."Change Type"::WHAMove:
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::Movement;
            MoveRequest."Change Type"::WHAIncrease:
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
            MoveRequest."Change Type"::WHADecrease:
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
        end;

        if MoveRequest."From Bin Code" <> '' then begin
            WarehouseJournalLine."From Zone Code" := ZoneOf(MoveRequest."Location Code", MoveRequest."From Bin Code");
            WarehouseJournalLine."From Bin Code" := MoveRequest."From Bin Code";
        end;
        if MoveRequest."To Bin Code" <> '' then begin
            WarehouseJournalLine."To Zone Code" := ZoneOf(MoveRequest."Location Code", MoveRequest."To Bin Code");
            WarehouseJournalLine."To Bin Code" := MoveRequest."To Bin Code";
        end;
    end;

    local procedure ReferenceDocumentOf(var MoveRequest: Record "WHA Whse. Move Request"): Enum "Whse. Reference Document Type"
    var
        ReferenceDocument: Enum "Whse. Reference Document Type";
    begin
        if MoveRequest."Change Type" = MoveRequest."Change Type"::WHAMove then
            exit(ReferenceDocument::Movement);
        exit(ReferenceDocument::"Item Journal");
    end;

    local procedure UnitOfMeasureOf(var MoveRequest: Record "WHA Whse. Move Request"; var Item: Record Item): Code[10]
    begin
        if MoveRequest."Unit of Measure Code" <> '' then
            exit(MoveRequest."Unit of Measure Code");
        exit(Item."Base Unit of Measure");
    end;

    local procedure RegisteringDateOf(var MoveRequest: Record "WHA Whse. Move Request"): Date
    begin
        if MoveRequest."Registering Date" = 0D then
            exit(WorkDate());
        exit(MoveRequest."Registering Date");
    end;

    local procedure ZoneOf(LocationCode: Code[10]; BinCode: Code[20]): Code[10]
    var
        Bin: Record Bin;
    begin
        Bin.SetLoadFields("Zone Code");
        if not Bin.Get(LocationCode, BinCode) then
            exit('');
        exit(Bin."Zone Code");
    end;
}
