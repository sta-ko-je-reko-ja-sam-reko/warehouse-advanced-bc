namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Warehouse.Document;

codeunit 50205 "WHA Src Whse. Receipt" implements "WHA ITaskSource"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Goods that have arrived and are standing in the receiving bin. Every line still to be received becomes a put-away, taken from the bin the receipt names.';
        LinkLbl: Label 'Warehouse receipt %1, line %2', Comment = '%1 = the warehouse receipt number, %2 = the line number';
        ReceiptMissingErr: Label 'Warehouse receipt %1 does not exist, so no work can be raised from it.', Comment = '%1 = the warehouse receipt number';

    /// <summary>
    /// Raises a put-away for every receipt line that still has something outstanding on it, skipping any
    /// line that already carries work nobody has cancelled.
    /// </summary>
    /// <param name="SourceNo">The warehouse receipt to read.</param>
    /// <returns>How many put-aways were raised.</returns>
    procedure Generate(SourceNo: Code[20]): Integer
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        Raised: Integer;
    begin
        WarehouseReceiptHeader.SetLoadFields("No.");
        if not WarehouseReceiptHeader.Get(SourceNo) then
            Error(ReceiptMissingErr, SourceNo);

        WarehouseReceiptLine.SetLoadFields("Line No.", "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code", "Qty. Outstanding", Description, "Due Date", "Source No.");
        WarehouseReceiptLine.SetRange("No.", SourceNo);
        WarehouseReceiptLine.SetFilter("Qty. Outstanding", '>%1', 0);
        if not WarehouseReceiptLine.FindSet() then
            exit(0);

        repeat
            if not TaskSourceMgt.HasOpenTask(SourceType::WHAWhseReceipt, SourceNo, WarehouseReceiptLine."Line No.") then begin
                RaisePutAway(WarehouseReceiptLine);
                Raised += 1;
            end;
        until WarehouseReceiptLine.Next() = 0;

        exit(Raised);
    end;

    /// <summary>
    /// Describes in one line what this kind of source is and what it turns into.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Names the receipt and line a task came from.
    /// </summary>
    /// <param name="WarehouseTask">The task to describe the origin of.</param>
    /// <returns>The origin in the user's language.</returns>
    procedure DescribeLink(var WarehouseTask: Record "WHA Warehouse Task"): Text
    begin
        exit(StrSubstNo(LinkLbl, WarehouseTask."Source No.", WarehouseTask."Source Line No."));
    end;

    /// <summary>
    /// Answers whether the receipt line still has something outstanding on it. A line received by some
    /// other route leaves a put-away nobody needs to walk.
    /// </summary>
    /// <param name="WarehouseTask">The task to check the origin of.</param>
    /// <returns>True while the receipt line still wants receiving.</returns>
    procedure SourceIsOpen(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetLoadFields("Qty. Outstanding");
        if not WarehouseReceiptLine.Get(WarehouseTask."Source No.", WarehouseTask."Source Line No.") then
            exit(false);
        exit(WarehouseReceiptLine."Qty. Outstanding" > 0);
    end;

    /// <summary>
    /// Opens the warehouse receipt the task was raised from.
    /// </summary>
    /// <param name="WarehouseTask">The task to show the origin of.</param>
    /// <returns>True when the receipt still exists and was opened.</returns>
    procedure ShowSource(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        if not WarehouseReceiptHeader.Get(WarehouseTask."Source No.") then
            exit(false);

        Page.Run(Page::"Warehouse Receipt", WarehouseReceiptHeader);
        exit(true);
    end;

    local procedure RaisePutAway(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        WarehouseTask.Init();
        WarehouseTask."Task Type" := WarehouseTask."Task Type"::WHAPutAway;
        WarehouseTask.Description := WarehouseReceiptLine.Description;
        WarehouseTask.Validate("Location Code", WarehouseReceiptLine."Location Code");
        WarehouseTask."From Bin Code" := WarehouseReceiptLine."Bin Code";
        WarehouseTask.Validate("Item No.", WarehouseReceiptLine."Item No.");
        WarehouseTask."Variant Code" := WarehouseReceiptLine."Variant Code";
        if WarehouseReceiptLine."Unit of Measure Code" <> '' then
            WarehouseTask."Unit of Measure Code" := WarehouseReceiptLine."Unit of Measure Code";
        WarehouseTask.Validate(Quantity, WarehouseReceiptLine."Qty. Outstanding");
        WarehouseTask."Due Date" := WarehouseReceiptLine."Due Date";

        TaskSourceMgt.StampSource(WarehouseTask, SourceType::WHAWhseReceipt, WarehouseReceiptLine."No.", WarehouseReceiptLine."Line No.", WarehouseReceiptLine."Source No.");
        WarehouseTask.Insert(true);
    end;
}
