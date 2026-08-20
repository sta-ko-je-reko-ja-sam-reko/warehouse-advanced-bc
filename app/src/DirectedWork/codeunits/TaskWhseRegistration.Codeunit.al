namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.HandlingUnit;
using WarehouseAdvanced.Registration;

codeunit 50209 "WHA Task Whse. Registration"
{
    Access = Public;

    var
        LineDescriptionLbl: Label 'Task %1', Comment = '%1 = the warehouse task number';

    /// <summary>
    /// Tells Business Central what a finished job moved, in whatever way the warehouse task setup asks
    /// for. This runs before the app moves the handling unit, because the bin the goods came from is
    /// still readable then and is not afterwards.
    /// </summary>
    /// <param name="WarehouseTask">The job that was finished. Read, not modified.</param>
    /// <param name="HandledQuantity">How much was actually moved, for a job that names an item.</param>
    /// <returns>How many moves reached Business Central's warehouse entries.</returns>
    internal procedure RegisterMove(var WarehouseTask: Record "WHA Warehouse Task"; HandledQuantity: Decimal): Integer
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        Setup: Record "WHA Warehouse Task Setup";
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
    begin
        if BuildRequest(WarehouseTask, HandledQuantity, TempMoveRequest) = 0 then
            exit(0);

        ReadSetup(Setup);
        exit(WhseRegMgt.Register(Setup."Whse. Registration Method", TempMoveRequest));
    end;

    /// <summary>
    /// Turns a finished job into the moves it made, without registering any of them. Kept apart from the
    /// registration itself so what a job would tell Business Central can be asserted without a warehouse
    /// to tell it to.
    /// </summary>
    /// <remarks>
    /// A job raised from a **warehouse activity** produces nothing here at all. Registering that activity
    /// writes the warehouse entries itself, and registering a movement as well would move the goods
    /// twice — the same "half of it is worse than neither half" rule the posting module already follows,
    /// pointing the other way.
    ///
    /// A job that names a handling unit moves the whole unit, so every line on it is a move. A job that
    /// names only an item moves that item alone. A job whose two ends are not both bins at one location
    /// is not a move Business Central can record, and produces nothing: goods leaving the warehouse are
    /// accounted for by posting the document, not by this.
    /// </remarks>
    /// <param name="WarehouseTask">The job to read.</param>
    /// <param name="HandledQuantity">How much was actually moved, for a job that names an item.</param>
    /// <param name="MoveRequest">Receives one line per move. Not cleared first.</param>
    /// <returns>How many lines were added.</returns>
    internal procedure BuildRequest(var WarehouseTask: Record "WHA Warehouse Task"; HandledQuantity: Decimal; var MoveRequest: Record "WHA Whse. Move Request"): Integer
    var
        HandlingUnit: Record "WHA Handling Unit";
        FromBinCode: Code[20];
    begin
        if (WarehouseTask."Location Code" = '') or (WarehouseTask."To Bin Code" = '') then
            exit(0);
        if WarehouseTask."Source Type" = WarehouseTask."Source Type"::WHAWhseActivity then
            exit(0);

        if WarehouseTask."Handling Unit No." <> '' then begin
            HandlingUnit.SetLoadFields("Location Code", "Bin Code");
            if not HandlingUnit.Get(WarehouseTask."Handling Unit No.") then
                exit(0);
            if HandlingUnit."Location Code" <> WarehouseTask."Location Code" then
                exit(0);

            FromBinCode := FromBinOf(WarehouseTask, HandlingUnit."Bin Code");
            if FromBinCode = '' then
                exit(0);
            exit(AddUnitLines(WarehouseTask, FromBinCode, MoveRequest));
        end;

        if (WarehouseTask."Item No." = '') or (HandledQuantity <= 0) then
            exit(0);

        FromBinCode := FromBinOf(WarehouseTask, '');
        if FromBinCode = '' then
            exit(0);

        AddItemLine(WarehouseTask, FromBinCode, HandledQuantity, MoveRequest);
        exit(1);
    end;

    local procedure AddUnitLines(var WarehouseTask: Record "WHA Warehouse Task"; FromBinCode: Code[20]; var MoveRequest: Record "WHA Whse. Move Request"): Integer
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
        Added: Integer;
    begin
        HandlingUnitLine.SetLoadFields("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Lot No.", "Serial No.");
        HandlingUnitLine.SetRange("Handling Unit No.", WarehouseTask."Handling Unit No.");
        HandlingUnitLine.SetFilter(Quantity, '>%1', 0);
        if not HandlingUnitLine.FindSet() then
            exit(0);

        repeat
            if HandlingUnitLine."Item No." <> '' then begin
                InitLine(WarehouseTask, FromBinCode, MoveRequest);
                MoveRequest."Item No." := HandlingUnitLine."Item No.";
                MoveRequest."Variant Code" := HandlingUnitLine."Variant Code";
                MoveRequest."Unit of Measure Code" := HandlingUnitLine."Unit of Measure Code";
                MoveRequest.Quantity := HandlingUnitLine.Quantity;
                MoveRequest."Lot No." := HandlingUnitLine."Lot No.";
                MoveRequest."Serial No." := HandlingUnitLine."Serial No.";
                MoveRequest.Insert(false);
                Added += 1;
            end;
        until HandlingUnitLine.Next() = 0;

        exit(Added);
    end;

    local procedure AddItemLine(var WarehouseTask: Record "WHA Warehouse Task"; FromBinCode: Code[20]; HandledQuantity: Decimal; var MoveRequest: Record "WHA Whse. Move Request")
    begin
        InitLine(WarehouseTask, FromBinCode, MoveRequest);
        MoveRequest."Item No." := WarehouseTask."Item No.";
        MoveRequest."Variant Code" := WarehouseTask."Variant Code";
        MoveRequest."Unit of Measure Code" := WarehouseTask."Unit of Measure Code";
        MoveRequest.Quantity := HandledQuantity;
        MoveRequest."Lot No." := WarehouseTask."Lot No.";
        MoveRequest."Serial No." := WarehouseTask."Serial No.";
        MoveRequest.Insert(false);
    end;

    local procedure InitLine(var WarehouseTask: Record "WHA Warehouse Task"; FromBinCode: Code[20]; var MoveRequest: Record "WHA Whse. Move Request")
    var
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
        NewEntryNo: Integer;
    begin
        NewEntryNo := WhseRegMgt.NextEntryNo(MoveRequest);

        MoveRequest.Init();
        MoveRequest."Entry No." := NewEntryNo;
        MoveRequest."Location Code" := WarehouseTask."Location Code";
        MoveRequest."From Bin Code" := FromBinCode;
        MoveRequest."To Bin Code" := WarehouseTask."To Bin Code";
        MoveRequest."Registering Date" := WorkDate();
        MoveRequest.Description := CopyStr(StrSubstNo(LineDescriptionLbl, WarehouseTask."No."), 1, MaxStrLen(MoveRequest.Description));
        MoveRequest."Reference No." := WarehouseTask."No.";
        MoveRequest."Source Table No." := Database::"WHA Warehouse Task";
        MoveRequest."Source No." := WarehouseTask."No.";
    end;

    local procedure FromBinOf(var WarehouseTask: Record "WHA Warehouse Task"; FallbackBinCode: Code[20]): Code[20]
    var
        FromBinCode: Code[20];
    begin
        FromBinCode := WarehouseTask."From Bin Code";
        if FromBinCode = '' then
            FromBinCode := FallbackBinCode;
        if FromBinCode = WarehouseTask."To Bin Code" then
            exit('');
        exit(FromBinCode);
    end;

    local procedure ReadSetup(var Setup: Record "WHA Warehouse Task Setup")
    begin
        Setup.SetLoadFields("Whse. Registration Method");
        if not Setup.Get() then
            Clear(Setup);
    end;
}
