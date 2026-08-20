namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Warehouse.Worksheet;
using WarehouseAdvanced.Registration;

codeunit 50217 "WHA Src Movement Wksh." implements "WHA ITaskSource"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Bin-to-bin moves somebody has worked out on a movement worksheet. Every line still outstanding becomes a movement, from the bin the line takes from to the bin it puts into.';
        LinkLbl: Label 'Movement worksheet %1, line %2', Comment = '%1 = the worksheet name, %2 = the line number';
        OwnActivitiesErr: Label 'Location %1 requires Business Central''s own put-away or pick, so it raises warehouse activities of its own for these lines. Raising warehouse tasks here as well would send an operator to the same bin twice. Turn off Require Put-away and Require Pick at that location, or leave this worksheet to Business Central.', Comment = '%1 = the location code';

    /// <summary>
    /// Raises a movement for every worksheet line that still has something outstanding on it, skipping
    /// any line that already carries work nobody has cancelled.
    /// </summary>
    /// <remarks>
    /// A movement worksheet line is already exactly the shape of a warehouse task: a from-bin, a to-bin,
    /// an item and a quantity. It is the only one of Business Central's internal warehouse documents this
    /// app can read — see the note in `WriteBack` and in
    /// `app/docs/location-configuration.md` for why the others cannot exist where this app runs.
    /// </remarks>
    /// <param name="SourceNo">The worksheet name to read.</param>
    /// <returns>How many movements were raised.</returns>
    procedure Generate(SourceNo: Code[20]): Integer
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        Raised: Integer;
    begin
        FilterToName(WhseWorksheetLine, SourceNo);
        WhseWorksheetLine.SetFilter("Qty. Outstanding", '>%1', 0);
        if not WhseWorksheetLine.FindSet() then
            exit(0);

        repeat
            CheckLocationRaisesNoActivities(WhseWorksheetLine);
            if not TaskSourceMgt.HasOpenTask(SourceType::WHAMovementWksh, SourceNo, WhseWorksheetLine."Line No.") then begin
                RaiseMovement(WhseWorksheetLine, SourceNo);
                Raised += 1;
            end;
        until WhseWorksheetLine.Next() = 0;

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
    /// Names the worksheet and line a task came from.
    /// </summary>
    /// <param name="WarehouseTask">The task to describe the origin of.</param>
    /// <returns>The origin in the user's language.</returns>
    procedure DescribeLink(var WarehouseTask: Record "WHA Warehouse Task"): Text
    begin
        exit(StrSubstNo(LinkLbl, WarehouseTask."Source No.", WarehouseTask."Source Line No."));
    end;

    /// <summary>
    /// Marks the worksheet line as handled — but only when the app actually moved the goods in Business
    /// Central's own records.
    /// </summary>
    /// <remarks>
    /// This is the one write-back in the app that guards itself on something other than a setting, and
    /// the reason is a hazard rather than a preference. A movement worksheet line exists to be turned
    /// into a Business Central movement. If this app walks the move and leaves the line outstanding,
    /// somebody creating a movement from that worksheet afterwards moves the same goods **a second
    /// time**.
    ///
    /// Marking it handled is honest only if the goods really did move where Business Central can see it,
    /// which is true exactly when warehouse registration is maintaining bin content — so that is what is
    /// asked. With registration off, the line is left alone: the app moved nothing Business Central knows
    /// about, and claiming otherwise would be worse than the duplication it was trying to avoid.
    /// </remarks>
    /// <param name="WarehouseTask">The finished movement.</param>
    /// <returns>True when the worksheet line was changed.</returns>
    procedure WriteBack(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        NewQuantity: Decimal;
    begin
        if WarehouseTask."Quantity Handled" <= 0 then
            exit(false);
        if not RegistrationMaintainsBins() then
            exit(false);
        if not FindLine(WarehouseTask, WhseWorksheetLine) then
            exit(false);

        NewQuantity := WhseWorksheetLine."Qty. Handled" + WarehouseTask."Quantity Handled";
        if NewQuantity > WhseWorksheetLine.Quantity then
            NewQuantity := WhseWorksheetLine.Quantity;
        if NewQuantity = WhseWorksheetLine."Qty. Handled" then
            exit(false);

        WhseWorksheetLine.Validate("Qty. Handled", NewQuantity);
        WhseWorksheetLine.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Answers whether the worksheet line still has something outstanding on it.
    /// </summary>
    /// <param name="WarehouseTask">The task to check the origin of.</param>
    /// <returns>True while the worksheet line still wants moving.</returns>
    procedure SourceIsOpen(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        if not FindLine(WarehouseTask, WhseWorksheetLine) then
            exit(false);
        exit(WhseWorksheetLine."Qty. Outstanding" > 0);
    end;

    /// <summary>
    /// Opens the movement worksheet the task was raised from.
    /// </summary>
    /// <param name="WarehouseTask">The task to show the origin of.</param>
    /// <returns>True when the worksheet line still exists and was opened.</returns>
    procedure ShowSource(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        if not FindLine(WarehouseTask, WhseWorksheetLine) then
            exit(false);

        Page.Run(Page::"Movement Worksheet", WhseWorksheetLine);
        exit(true);
    end;

    local procedure FilterToName(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceNo: Code[20])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        if WhseWorksheetTemplate.FindFirst() then
            WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);

        WhseWorksheetLine.SetRange(Name, CopyStr(SourceNo, 1, 10));
    end;

    local procedure FindLine(var WarehouseTask: Record "WHA Warehouse Task"; var WhseWorksheetLine: Record "Whse. Worksheet Line"): Boolean
    begin
        FilterToName(WhseWorksheetLine, WarehouseTask."Source No.");
        if WarehouseTask."Location Code" <> '' then
            WhseWorksheetLine.SetRange("Location Code", WarehouseTask."Location Code");
        WhseWorksheetLine.SetRange("Line No.", WarehouseTask."Source Line No.");
        exit(WhseWorksheetLine.FindFirst());
    end;

    local procedure RegistrationMaintainsBins(): Boolean
    var
        Setup: Record "WHA Warehouse Task Setup";
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
    begin
        Setup.SetLoadFields("Whse. Registration Method");
        if not Setup.Get() then
            exit(false);
        exit(WhseRegMgt.UpdatesBinContent(Setup."Whse. Registration Method"));
    end;

    local procedure CheckLocationRaisesNoActivities(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
    begin
        if not WhseRegMgt.LocationRaisesOwnActivities(WhseWorksheetLine."Location Code") then
            exit;
        Error(OwnActivitiesErr, WhseWorksheetLine."Location Code");
    end;

    local procedure RaiseMovement(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceNo: Code[20])
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        WarehouseTask.Init();
        WarehouseTask."Task Type" := WarehouseTask."Task Type"::WHAMovement;
        WarehouseTask.Description := WhseWorksheetLine.Description;
        WarehouseTask.Validate("Location Code", WhseWorksheetLine."Location Code");
        WarehouseTask."From Bin Code" := WhseWorksheetLine."From Bin Code";
        WarehouseTask."To Bin Code" := WhseWorksheetLine."To Bin Code";
        WarehouseTask.Validate("Item No.", WhseWorksheetLine."Item No.");
        WarehouseTask."Variant Code" := WhseWorksheetLine."Variant Code";
        if WhseWorksheetLine."Unit of Measure Code" <> '' then
            WarehouseTask."Unit of Measure Code" := WhseWorksheetLine."Unit of Measure Code";
        WarehouseTask.Validate(Quantity, WhseWorksheetLine."Qty. Outstanding");
        WarehouseTask."Due Date" := WhseWorksheetLine."Due Date";

        TaskSourceMgt.StampSource(WarehouseTask, SourceType::WHAMovementWksh, SourceNo, WhseWorksheetLine."Line No.", '');
        WarehouseTask.Insert(true);
    end;
}
