namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Warehouse.Document;
using WarehouseAdvanced.Registration;

codeunit 50206 "WHA Src Whse. Shipment" implements "WHA ITaskSource"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Goods that are due to leave. Every line still to be shipped becomes a pick, ending at the bin the shipment names. Where the goods are picked from is left open, because that is a question about stock and not about the document.';
        LinkLbl: Label 'Warehouse shipment %1, line %2', Comment = '%1 = the warehouse shipment number, %2 = the line number';
        OwnActivitiesErr: Label 'Location %%1 requires Business Central''s own put-away or pick, so it raises warehouse activities of its own for these lines. Raising warehouse tasks here as well would send an operator to the same bin twice. Turn off Require Put-away and Require Pick at that location, or leave this warehouse shipment to Business Central.', Comment = '%%1 = the location code';
        ShipmentMissingErr: Label 'Warehouse shipment %1 does not exist, so no work can be raised from it.', Comment = '%1 = the warehouse shipment number';

    /// <summary>
    /// Raises a pick for every shipment line that still has something outstanding on it, skipping any
    /// line that already carries work nobody has cancelled.
    /// </summary>
    /// <param name="SourceNo">The warehouse shipment to read.</param>
    /// <returns>How many picks were raised.</returns>
    procedure Generate(SourceNo: Code[20]): Integer
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        Raised: Integer;
    begin
        WarehouseShipmentHeader.SetLoadFields("No.");
        if not WarehouseShipmentHeader.Get(SourceNo) then
            Error(ShipmentMissingErr, SourceNo);

        WarehouseShipmentLine.SetLoadFields("Line No.", "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code", "Qty. Outstanding", Description, "Due Date", "Source No.");
        WarehouseShipmentLine.SetRange("No.", SourceNo);
        WarehouseShipmentLine.SetFilter("Qty. Outstanding", '>%1', 0);
        if not WarehouseShipmentLine.FindSet() then
            exit(0);

        CheckLocationRaisesNoActivities(WarehouseShipmentLine);

        repeat
            if not TaskSourceMgt.HasOpenTask(SourceType::WHAWhseShipment, SourceNo, WarehouseShipmentLine."Line No.") then begin
                RaisePick(WarehouseShipmentLine);
                Raised += 1;
            end;
        until WarehouseShipmentLine.Next() = 0;

        exit(Raised);
    end;

    local procedure CheckLocationRaisesNoActivities(var WarehouseShipmentLine: Record "Warehouse shipment Line")
    var
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
    begin
        if not WhseRegMgt.LocationRaisesOwnActivities(WarehouseShipmentLine."Location Code") then
            exit;
        Error(OwnActivitiesErr, WarehouseShipmentLine."Location Code");
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
    /// Names the shipment and line a task came from.
    /// </summary>
    /// <param name="WarehouseTask">The task to describe the origin of.</param>
    /// <returns>The origin in the user's language.</returns>
    procedure DescribeLink(var WarehouseTask: Record "WHA Warehouse Task"): Text
    begin
        exit(StrSubstNo(LinkLbl, WarehouseTask."Source No.", WarehouseTask."Source Line No."));
    end;

    /// <summary>
    /// Adds what was picked to `Qty. to Ship` on the shipment line, without going past what the line
    /// still has outstanding. It adds rather than sets, for the same reason the receipt side does: two
    /// picks against one line must leave the line holding both.
    /// </summary>
    /// <param name="WarehouseTask">The finished pick.</param>
    /// <returns>True when the shipment line was changed.</returns>
    procedure WriteBack(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        NewQuantity: Decimal;
    begin
        if WarehouseTask."Quantity Handled" <= 0 then
            exit(false);

        WarehouseShipmentLine.SetLoadFields("Qty. Outstanding", "Qty. to Ship");
        if not WarehouseShipmentLine.Get(WarehouseTask."Source No.", WarehouseTask."Source Line No.") then
            exit(false);

        NewQuantity := WarehouseShipmentLine."Qty. to Ship" + WarehouseTask."Quantity Handled";
        if NewQuantity > WarehouseShipmentLine."Qty. Outstanding" then
            NewQuantity := WarehouseShipmentLine."Qty. Outstanding";
        if NewQuantity = WarehouseShipmentLine."Qty. to Ship" then
            exit(false);

        WarehouseShipmentLine.Validate("Qty. to Ship", NewQuantity);
        WarehouseShipmentLine.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Answers whether the shipment line still has something outstanding on it. A line shipped by some
    /// other route leaves a pick nobody needs to walk.
    /// </summary>
    /// <param name="WarehouseTask">The task to check the origin of.</param>
    /// <returns>True while the shipment line still wants picking.</returns>
    procedure SourceIsOpen(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetLoadFields("Qty. Outstanding");
        if not WarehouseShipmentLine.Get(WarehouseTask."Source No.", WarehouseTask."Source Line No.") then
            exit(false);
        exit(WarehouseShipmentLine."Qty. Outstanding" > 0);
    end;

    /// <summary>
    /// Opens the warehouse shipment the task was raised from.
    /// </summary>
    /// <param name="WarehouseTask">The task to show the origin of.</param>
    /// <returns>True when the shipment still exists and was opened.</returns>
    procedure ShowSource(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        if not WarehouseShipmentHeader.Get(WarehouseTask."Source No.") then
            exit(false);

        Page.Run(Page::"Warehouse Shipment", WarehouseShipmentHeader);
        exit(true);
    end;

    local procedure RaisePick(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        WarehouseTask.Init();
        WarehouseTask."Task Type" := WarehouseTask."Task Type"::WHAPick;
        WarehouseTask.Description := WarehouseShipmentLine.Description;
        WarehouseTask.Validate("Location Code", WarehouseShipmentLine."Location Code");
        WarehouseTask."To Bin Code" := WarehouseShipmentLine."Bin Code";
        WarehouseTask.Validate("Item No.", WarehouseShipmentLine."Item No.");
        WarehouseTask."Variant Code" := WarehouseShipmentLine."Variant Code";
        if WarehouseShipmentLine."Unit of Measure Code" <> '' then
            WarehouseTask."Unit of Measure Code" := WarehouseShipmentLine."Unit of Measure Code";
        WarehouseTask.Validate(Quantity, WarehouseShipmentLine."Qty. Outstanding");
        WarehouseTask."Due Date" := WarehouseShipmentLine."Due Date";

        TaskSourceMgt.StampSource(WarehouseTask, SourceType::WHAWhseShipment, WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.", WarehouseShipmentLine."Source No.");
        WarehouseTask.Insert(true);
    end;
}
