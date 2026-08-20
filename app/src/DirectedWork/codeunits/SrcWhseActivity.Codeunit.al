namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;

codeunit 50219 "WHA Src Whse. Activity" implements "WHA ITaskSource"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Work Business Central has already worked out for itself — a put-away, a pick or a movement. Each job it raised becomes a job on this queue, and finishing one here registers it there.';
        LinkLbl: Label 'Warehouse activity %1, line %2', Comment = '%1 = the activity number, %2 = the line number';
        ActivityMissingErr: Label 'Warehouse activity %1 has no lines, so no work can be raised from it.', Comment = '%1 = the warehouse activity number';
        AmbiguousErr: Label 'More than one kind of warehouse activity is numbered %1, so there is no telling which one to work from. Register it in Business Central instead.', Comment = '%1 = the warehouse activity number';

    /// <summary>
    /// Raises a job for every line Business Central is still waiting to have handled.
    /// </summary>
    /// <remarks>
    /// **One job is a pair of lines, not a line.** Business Central splits a put-away, a pick and a
    /// movement into a `Take` from one bin and a `Place` into another, and registering expects both. So a
    /// task is raised from the `Take` and carries the `Place`'s bin as its destination, which is exactly
    /// the shape a warehouse task already has. An inventory put-away or pick has a single line and no
    /// action type, and becomes a job with one end.
    ///
    /// This source and the document sources cannot both fire at one location, and nothing enforces that
    /// because Business Central already does: a location that raises activities is one the document
    /// sources refuse, and a location that raises none has nothing here to read.
    /// </remarks>
    /// <param name="SourceNo">The warehouse activity to read.</param>
    /// <returns>How many jobs were raised.</returns>
    procedure Generate(SourceNo: Code[20]): Integer
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        Raised: Integer;
    begin
        FilterToActivity(WarehouseActivityLine, SourceNo);
        WarehouseActivityLine.SetFilter("Qty. Outstanding", '>%1', 0);
        WarehouseActivityLine.SetFilter("Action Type", '%1|%2', WarehouseActivityLine."Action Type"::" ", WarehouseActivityLine."Action Type"::Take);
        if not WarehouseActivityLine.FindSet() then
            exit(0);

        repeat
            if not TaskSourceMgt.HasOpenTask(SourceType::WHAWhseActivity, SourceNo, WarehouseActivityLine."Line No.") then begin
                RaiseTask(WarehouseActivityLine, SourceNo);
                Raised += 1;
            end;
        until WarehouseActivityLine.Next() = 0;

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
    /// Names the activity and line a task came from.
    /// </summary>
    /// <param name="WarehouseTask">The task to describe the origin of.</param>
    /// <returns>The origin in the user's language.</returns>
    procedure DescribeLink(var WarehouseTask: Record "WHA Warehouse Task"): Text
    begin
        exit(StrSubstNo(LinkLbl, WarehouseTask."Source No.", WarehouseTask."Source Line No."));
    end;

    /// <summary>
    /// Registers the warehouse activity the finished job came from.
    /// </summary>
    /// <remarks>
    /// This is the point the whole source exists for, and it is not a write-back in the sense the other
    /// sources mean. A receipt line is *told* what was handled and posted later by somebody else; a
    /// warehouse activity is **registered here and now**, which moves the stock, writes the warehouse
    /// entries and closes Business Central's own job.
    ///
    /// It goes through `Whse.-Activity-Register` — the codeunit Business Central's own page action uses.
    /// The Yes/No wrapper around it adds only a source-document check, a balance check and a
    /// confirmation; the first two are kept and the dialog is not, because nothing here runs anywhere a
    /// person could answer one. `CheckBalanceQtyToHandle` is the one that matters: the `Take` and the
    /// `Place` must agree, and an operator who moved less than the job asked for has to say so on both.
    /// </remarks>
    /// <param name="WarehouseTask">The finished job.</param>
    /// <returns>True when the activity was registered.</returns>
    procedure WriteBack(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        TakeLine: Record "Warehouse Activity Line";
        ToRegister: Record "Warehouse Activity Line";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
    begin
        if WarehouseTask."Quantity Handled" <= 0 then
            exit(false);
        if not FindLine(WarehouseTask, TakeLine) then
            exit(false);

        if not SetQuantityToHandle(TakeLine, WarehouseTask."Quantity Handled") then
            exit(false);

        FilterToPair(ToRegister, TakeLine);
        if ToRegister.IsEmpty() then
            exit(false);

        WhseActivityRegister.Run(ToRegister);
        exit(true);
    end;

    /// <summary>
    /// Answers whether Business Central is still waiting for this job.
    /// </summary>
    /// <param name="WarehouseTask">The task to check the origin of.</param>
    /// <returns>True while the activity line still has something outstanding.</returns>
    procedure SourceIsOpen(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if not FindLine(WarehouseTask, WarehouseActivityLine) then
            exit(false);
        exit(WarehouseActivityLine."Qty. Outstanding" > 0);
    end;

    /// <summary>
    /// Opens the warehouse activity the task was raised from.
    /// </summary>
    /// <param name="WarehouseTask">The task to show the origin of.</param>
    /// <returns>True when the activity still exists and was opened.</returns>
    procedure ShowSource(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        if not FindLine(WarehouseTask, WarehouseActivityLine) then
            exit(false);
        if not WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.") then
            exit(false);

        Page.Run(0, WarehouseActivityHeader);
        exit(true);
    end;

    /// <summary>
    /// Narrows a warehouse activity line record to one activity, whatever kind it is.
    /// </summary>
    /// <remarks>
    /// A warehouse activity is identified by its **kind and its number**, and a warehouse task has room
    /// for one code. Business Central numbers each kind from its own series, so a number is nearly always
    /// unique — but nearly is not a word to move stock on, so two kinds sharing a number is refused
    /// rather than guessed at.
    /// </remarks>
    /// <param name="WarehouseActivityLine">The record to filter.</param>
    /// <param name="SourceNo">The activity number.</param>
    internal procedure FilterToActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20])
    var
        Probe: Record "Warehouse Activity Line";
        FoundType: Enum "Warehouse Activity Type";
        Seen: Boolean;
    begin
        Probe.SetCurrentKey("No.", "Line No.", "Activity Type");
        Probe.SetRange("No.", SourceNo);
        if not Probe.FindSet() then
            Error(ActivityMissingErr, SourceNo);

        repeat
            if Seen and (Probe."Activity Type" <> FoundType) then
                Error(AmbiguousErr, SourceNo);
            FoundType := Probe."Activity Type";
            Seen := true;
        until Probe.Next() = 0;

        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Activity Type", FoundType);
        WarehouseActivityLine.SetRange("No.", SourceNo);
    end;

    local procedure FindLine(var WarehouseTask: Record "WHA Warehouse Task"; var WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    begin
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetCurrentKey("No.", "Line No.", "Activity Type");
        WarehouseActivityLine.SetRange("No.", WarehouseTask."Source No.");
        WarehouseActivityLine.SetRange("Line No.", WarehouseTask."Source Line No.");
        exit(WarehouseActivityLine.FindFirst());
    end;

    /// <summary>
    /// Narrows to the one job a take line belongs to: itself and the place line that answers it.
    /// </summary>
    /// <remarks>
    /// The pairing is Business Central's own, taken from the key it keeps them under — a take and its
    /// place agree on the source they serve, the unit they are measured in and the break-bulk they
    /// belong to, and differ only in the action.
    /// </remarks>
    /// <param name="ToRegister">Receives the filtered pair.</param>
    /// <param name="TakeLine">The take line, or the single line of an inventory activity.</param>
    internal procedure FilterToPair(var ToRegister: Record "Warehouse Activity Line"; var TakeLine: Record "Warehouse Activity Line")
    begin
        ToRegister.Reset();
        ToRegister.SetRange("Activity Type", TakeLine."Activity Type");
        ToRegister.SetRange("No.", TakeLine."No.");
        ToRegister.SetRange("Source Type", TakeLine."Source Type");
        ToRegister.SetRange("Source Subtype", TakeLine."Source Subtype");
        ToRegister.SetRange("Source No.", TakeLine."Source No.");
        ToRegister.SetRange("Source Line No.", TakeLine."Source Line No.");
        ToRegister.SetRange("Source Subline No.", TakeLine."Source Subline No.");
        ToRegister.SetRange("Unit of Measure Code", TakeLine."Unit of Measure Code");
        ToRegister.SetRange("Breakbulk No.", TakeLine."Breakbulk No.");
    end;

    local procedure SetQuantityToHandle(var TakeLine: Record "Warehouse Activity Line"; Handled: Decimal): Boolean
    var
        PairLine: Record "Warehouse Activity Line";
        WMSMgt: Codeunit "WMS Management";
        Quantity: Decimal;
        Changed: Boolean;
    begin
        FilterToPair(PairLine, TakeLine);
        if not PairLine.FindSet() then
            exit(false);

        repeat
            Quantity := Handled;
            if Quantity > PairLine."Qty. Outstanding" then
                Quantity := PairLine."Qty. Outstanding";
            if Quantity > 0 then begin
                PairLine.Validate("Qty. to Handle", Quantity);
                PairLine.Modify(true);
                Changed := true;
            end;
        until PairLine.Next() = 0;

        if not Changed then
            exit(false);

        PairLine.FindFirst();
        WMSMgt.CheckBalanceQtyToHandle(PairLine);
        exit(true);
    end;

    local procedure RaiseTask(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20])
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
    begin
        WarehouseTask.Init();
        WarehouseTask."Task Type" := TaskTypeOf(WarehouseActivityLine."Activity Type");
        WarehouseTask.Description := WarehouseActivityLine.Description;
        WarehouseTask.Validate("Location Code", WarehouseActivityLine."Location Code");
        SetBins(WarehouseTask, WarehouseActivityLine);
        WarehouseTask.Validate("Item No.", WarehouseActivityLine."Item No.");
        WarehouseTask."Variant Code" := WarehouseActivityLine."Variant Code";
        if WarehouseActivityLine."Unit of Measure Code" <> '' then
            WarehouseTask."Unit of Measure Code" := WarehouseActivityLine."Unit of Measure Code";
        WarehouseTask.Validate(Quantity, WarehouseActivityLine."Qty. Outstanding");
        WarehouseTask."Lot No." := WarehouseActivityLine."Lot No.";
        WarehouseTask."Serial No." := WarehouseActivityLine."Serial No.";
        WarehouseTask."Due Date" := WarehouseActivityLine."Due Date";

        TaskSourceMgt.StampSource(WarehouseTask, SourceType::WHAWhseActivity, SourceNo, WarehouseActivityLine."Line No.", WarehouseActivityLine."Source No.");
        WarehouseTask.Insert(true);
    end;

    local procedure SetBins(var WarehouseTask: Record "WHA Warehouse Task"; var TakeLine: Record "Warehouse Activity Line")
    var
        PlaceLine: Record "Warehouse Activity Line";
    begin
        if TakeLine."Action Type" = TakeLine."Action Type"::" " then begin
            if TakeLine."Activity Type" = TakeLine."Activity Type"::"Invt. Pick" then
                WarehouseTask."From Bin Code" := TakeLine."Bin Code"
            else
                WarehouseTask."To Bin Code" := TakeLine."Bin Code";
            exit;
        end;

        WarehouseTask."From Bin Code" := TakeLine."Bin Code";

        FilterToPair(PlaceLine, TakeLine);
        PlaceLine.SetRange("Action Type", PlaceLine."Action Type"::Place);
        if PlaceLine.FindFirst() then
            WarehouseTask."To Bin Code" := PlaceLine."Bin Code";
    end;

    local procedure TaskTypeOf(ActivityType: Enum "Warehouse Activity Type"): Enum "WHA Warehouse Task Type"
    var
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        case ActivityType of
            ActivityType::"Put-away", ActivityType::"Invt. Put-away":
                exit(TaskType::WHAPutAway);
            ActivityType::Pick, ActivityType::"Invt. Pick":
                exit(TaskType::WHAPick);
        end;
        exit(TaskType::WHAMovement);
    end;
}
