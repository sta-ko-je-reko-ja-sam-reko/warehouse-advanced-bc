namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using WarehouseAdvanced.HandlingUnit;

codeunit 50200 "WHA Warehouse Task Logic" implements "WHA IWarehouseTask"
{
    Access = Public;

    var
        NoSeriesMissingErr: Label 'Set the warehouse task number series on the directed work setup page before creating warehouse tasks.';
        ShippedUnitErr: Label 'Handling unit %1 has already been shipped, so no more work can be planned for it.', Comment = '%1 = the handling unit number';
        UnitNotAvailableErr: Label 'Handling unit %1 is %2, so no work can be planned for it.', Comment = '%1 = the handling unit number, %2 = the status of the handling unit';
        NegativeQuantityErr: Label 'The quantity on a warehouse task cannot be negative.';
        NegativePriorityErr: Label 'The priority of a warehouse task cannot be negative. A lower number is more urgent, so zero is the most urgent value.';
        ReleaseNotAllowedErr: Label 'Only a created warehouse task can be released. Warehouse task %1 is %2.', Comment = '%1 = the warehouse task number, %2 = the current status';
        LocationMissingErr: Label 'Specify a location on warehouse task %1 before releasing it, so the work can be given to the right part of the warehouse.', Comment = '%1 = the warehouse task number';
        NothingToMoveErr: Label 'Specify a handling unit, or an item and a quantity, on warehouse task %1 before releasing it.', Comment = '%1 = the warehouse task number';
        AssignNotAllowedErr: Label 'Warehouse task %1 cannot be assigned while its status is %2. Release it first, and return work that has already started before giving it to someone else.', Comment = '%1 = the warehouse task number, %2 = the current status';
        StartNotAllowedErr: Label 'Warehouse task %1 must be assigned to someone before it can be started. Its status is %2.', Comment = '%1 = the warehouse task number, %2 = the current status';
        CompleteNotAllowedErr: Label 'Only a warehouse task that is in progress can be completed. Warehouse task %1 is %2.', Comment = '%1 = the warehouse task number, %2 = the current status';
        CancelNotAllowedErr: Label 'Warehouse task %1 is already %2, so it cannot be cancelled.', Comment = '%1 = the warehouse task number, %2 = the current status';
        UserTaskLimitErr: Label '%1 already holds %2 warehouse task(s), which is the most the warehouse task setup allows. Finish or hand back a task before taking another.', Comment = '%1 = the user the task would be assigned to, %2 = how many open tasks that user already holds';
        DeleteNotAllowedErr: Label 'Warehouse task %1 cannot be deleted while its status is %2. Cancel it instead, so the record of the work is kept.', Comment = '%1 = the warehouse task number, %2 = the current status';
        NotCountedErr: Label 'Warehouse task %1 does not move a counted quantity, so there is nothing to be short of. Complete it or hand it back.', Comment = '%1 = the warehouse task number';
        TooMuchErr: Label 'Warehouse task %1 asked for %2, so %3 cannot have been moved. Complete the task instead of reporting it short.', Comment = '%1 = the warehouse task number, %2 = the quantity asked for, %3 = the quantity entered';
        NegativeHandledErr: Label 'The quantity moved cannot be negative.';
        FollowUpDescLbl: Label 'Outstanding from %1', Comment = '%1 = the warehouse task number that came up short';

    /// <summary>
    /// Assigns the number series value, the default priority, and releases the task when the setup asks
    /// for tasks to be released automatically.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being inserted.</param>
    procedure Trigger_OnInsert(var WarehouseTask: Record "WHA Warehouse Task")
    var
        Setup: Record "WHA Warehouse Task Setup";
    begin
        if WarehouseTask."No." = '' then
            WarehouseTask."No." := NextTaskNo();

        DefaultTrackingFromUnit(WarehouseTask);

        Setup.SetLoadFields("Default Priority", "Auto Release Tasks");
        if not Setup.Get() then
            exit;

        if WarehouseTask.Priority = 0 then
            WarehouseTask.Priority := Setup."Default Priority";

        if not Setup."Auto Release Tasks" then
            exit;
        if WarehouseTask.Status <> WarehouseTask.Status::WHACreated then
            exit;
        if not IsReadyForWork(WarehouseTask) then
            exit;

        WarehouseTask.Status := WarehouseTask.Status::WHAReleased;
    end;

    /// <summary>
    /// Refuses the delete when the task is being worked or has been completed, so the record of the work
    /// survives.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being deleted.</param>
    procedure Trigger_OnDelete(var WarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask.Status in [WarehouseTask.Status::WHAInProgress, WarehouseTask.Status::WHACompleted] then
            Error(DeleteNotAllowedErr, WarehouseTask."No.", WarehouseTask.Status);
    end;

    /// <summary>
    /// Clears both bins when the location changes, so a bin from the previous location cannot be kept.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_LocationCode(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask."Location Code" = xWarehouseTask."Location Code" then
            exit;

        WarehouseTask."From Bin Code" := '';
        WarehouseTask."To Bin Code" := '';
    end;

    /// <summary>
    /// Copies the location and bin of the handling unit onto the task, and refuses a unit that has
    /// already shipped.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_HandlingUnitNo(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task")
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        if WarehouseTask."Handling Unit No." = xWarehouseTask."Handling Unit No." then
            exit;
        if WarehouseTask."Handling Unit No." = '' then
            exit;

        HandlingUnit.SetLoadFields(Status, "Location Code", "Bin Code");
        if not HandlingUnit.Get(WarehouseTask."Handling Unit No.") then
            exit;

        if HandlingUnit.Status = HandlingUnit.Status::WHAShipped then
            Error(ShippedUnitErr, HandlingUnit."No.");
        if not (HandlingUnit.Status in [HandlingUnit.Status::WHAOpen, HandlingUnit.Status::WHAClosed]) then
            Error(UnitNotAvailableErr, HandlingUnit."No.", HandlingUnit.Status);

        if HandlingUnit."Location Code" = '' then
            exit;

        WarehouseTask."Location Code" := HandlingUnit."Location Code";
        WarehouseTask."From Bin Code" := HandlingUnit."Bin Code";
        WarehouseTask."To Bin Code" := '';
    end;

    /// <summary>
    /// Clears the variant and unit of measure when the item changes, then copies the base unit of
    /// measure from the item.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_ItemNo(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task")
    var
        Item: Record Item;
    begin
        if WarehouseTask."Item No." = xWarehouseTask."Item No." then
            exit;

        WarehouseTask."Variant Code" := '';
        WarehouseTask."Unit of Measure Code" := '';

        if WarehouseTask."Item No." = '' then
            exit;

        Item.SetLoadFields("Base Unit of Measure");
        if not Item.Get(WarehouseTask."Item No.") then
            exit;

        WarehouseTask."Unit of Measure Code" := Item."Base Unit of Measure";
    end;

    /// <summary>
    /// Rejects a negative quantity.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_Quantity(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask.Quantity < 0 then
            Error(NegativeQuantityErr);
    end;

    /// <summary>
    /// Rejects a negative priority.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_Priority(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask.Priority < 0 then
            Error(NegativePriorityErr);
    end;

    /// <summary>
    /// Moves the task between people. Refuses handing started work straight to someone else, and
    /// enforces the limit on how many tasks one person may hold. Clearing the user returns the task to
    /// the queue — including work that had been started, which is how an operator abandons a job.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_AssignedToUserID(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask."Assigned To User ID" = xWarehouseTask."Assigned To User ID" then
            exit;

        if WarehouseTask."Assigned To User ID" = '' then begin
            WarehouseTask."Assigned At" := 0DT;
            if WarehouseTask.Status in [WarehouseTask.Status::WHAAssigned, WarehouseTask.Status::WHAInProgress] then begin
                WarehouseTask.Status := WarehouseTask.Status::WHAReleased;
                WarehouseTask."Started At" := 0DT;
            end;
            exit;
        end;

        if not (WarehouseTask.Status in [WarehouseTask.Status::WHAReleased, WarehouseTask.Status::WHAAssigned]) then
            Error(AssignNotAllowedErr, WarehouseTask."No.", WarehouseTask.Status);

        CheckUserTaskLimit(WarehouseTask);

        WarehouseTask."Assigned At" := CurrentDateTime;
        WarehouseTask.Status := WarehouseTask.Status::WHAAssigned;
    end;

    /// <summary>
    /// Makes the task available to the floor. Refuses a task that does not yet say where the work is or
    /// what is being moved.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to release.</param>
    procedure Release(var WarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask.Status <> WarehouseTask.Status::WHACreated then
            Error(ReleaseNotAllowedErr, WarehouseTask."No.", WarehouseTask.Status);
        if WarehouseTask."Location Code" = '' then
            Error(LocationMissingErr, WarehouseTask."No.");
        if not HasSomethingToMove(WarehouseTask) then
            Error(NothingToMoveErr, WarehouseTask."No.");

        WarehouseTask.Status := WarehouseTask.Status::WHAReleased;
        WarehouseTask.Modify(true);
    end;

    /// <summary>
    /// Gives a released task to a person and records when it happened.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to assign.</param>
    /// <param name="AssignToUserId">The user the task is assigned to.</param>
    procedure Assign(var WarehouseTask: Record "WHA Warehouse Task"; AssignToUserId: Code[50])
    begin
        WarehouseTask.Validate("Assigned To User ID", AssignToUserId);
        WarehouseTask.Modify(true);
    end;

    /// <summary>
    /// Marks an assigned task as being worked and records when it started.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to start.</param>
    procedure Start(var WarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask.Status <> WarehouseTask.Status::WHAAssigned then
            Error(StartNotAllowedErr, WarehouseTask."No.", WarehouseTask.Status);

        WarehouseTask."Started At" := CurrentDateTime;
        WarehouseTask.Status := WarehouseTask.Status::WHAInProgress;
        WarehouseTask.Modify(true);
    end;

    /// <summary>
    /// Marks a task as done, records when it finished, and moves the handling unit it carried to the
    /// destination the task names.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to complete.</param>
    procedure Complete(var WarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask.Status <> WarehouseTask.Status::WHAInProgress then
            Error(CompleteNotAllowedErr, WarehouseTask."No.", WarehouseTask.Status);

        WarehouseTask."Quantity Handled" := WarehouseTask.Quantity;
        WarehouseTask."Completed At" := CurrentDateTime;
        WarehouseTask.Status := WarehouseTask.Status::WHACompleted;
        WarehouseTask.Modify(true);

        MoveHandlingUnit(WarehouseTask);
        WriteBackToDocument(WarehouseTask);
    end;

    /// <summary>
    /// Finishes a task with less than it asked for, recording how much was moved and why the rest was
    /// not. Raises a follow-up task for the remainder when the setup asks for one.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to complete short.</param>
    /// <param name="HandledQuantity">How much was actually moved. Zero when nothing could be.</param>
    /// <param name="Reason">Why the rest was not moved.</param>
    procedure CompleteShort(var WarehouseTask: Record "WHA Warehouse Task"; HandledQuantity: Decimal; Reason: Enum "WHA Whse. Short Reason")
    var
        Outstanding: Decimal;
    begin
        if WarehouseTask.Status <> WarehouseTask.Status::WHAInProgress then
            Error(CompleteNotAllowedErr, WarehouseTask."No.", WarehouseTask.Status);
        if WarehouseTask.Quantity <= 0 then
            Error(NotCountedErr, WarehouseTask."No.");
        if HandledQuantity < 0 then
            Error(NegativeHandledErr);
        if HandledQuantity > WarehouseTask.Quantity then
            Error(TooMuchErr, WarehouseTask."No.", WarehouseTask.Quantity, HandledQuantity);

        Outstanding := WarehouseTask.Quantity - HandledQuantity;

        WarehouseTask."Quantity Handled" := HandledQuantity;
        WarehouseTask."Short Reason" := Reason;
        WarehouseTask."Completed At" := CurrentDateTime;
        WarehouseTask.Status := WarehouseTask.Status::WHACompleted;
        WarehouseTask.Modify(true);

        if HandledQuantity > 0 then begin
            MoveHandlingUnit(WarehouseTask);
            WriteBackToDocument(WarehouseTask);
        end;

        if Outstanding > 0 then
            CreateFollowUp(WarehouseTask, Outstanding);
    end;

    /// <summary>
    /// Withdraws a task that is no longer needed, keeping it as a record of what was asked for.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to cancel.</param>
    procedure Cancel(var WarehouseTask: Record "WHA Warehouse Task")
    begin
        if WarehouseTask.Status in [WarehouseTask.Status::WHACompleted, WarehouseTask.Status::WHACancelled] then
            Error(CancelNotAllowedErr, WarehouseTask."No.", WarehouseTask.Status);

        WarehouseTask.Status := WarehouseTask.Status::WHACancelled;
        WarehouseTask.Modify(true);
    end;

    /// <summary>
    /// Answers what a person should work on next: their own unfinished work first, then the most urgent
    /// released task at the location, which is assigned to them as it is handed over.
    /// </summary>
    /// <param name="ForUserId">The person asking for work.</param>
    /// <param name="LocationCode">The location to look in. Blank looks everywhere.</param>
    /// <param name="WarehouseTask">Receives the task the person should work on.</param>
    /// <returns>True when there is work to do.</returns>
    procedure GetNextForUser(ForUserId: Code[50]; LocationCode: Code[10]; var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        Status: Enum "WHA Warehouse Task Status";
    begin
        if FindOwnWork(ForUserId, LocationCode, Status::WHAInProgress, WarehouseTask) then
            exit(true);
        if FindOwnWork(ForUserId, LocationCode, Status::WHAAssigned, WarehouseTask) then
            exit(true);
        if not FindMostUrgentReleased(LocationCode, WarehouseTask) then
            exit(false);

        Assign(WarehouseTask, ForUserId);
        exit(true);
    end;

    local procedure FindOwnWork(ForUserId: Code[50]; LocationCode: Code[10]; SearchStatus: Enum "WHA Warehouse Task Status"; var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    begin
        WarehouseTask.Reset();
        WarehouseTask.SetCurrentKey("Assigned To User ID", Status, Priority);
        WarehouseTask.SetRange("Assigned To User ID", ForUserId);
        WarehouseTask.SetRange(Status, SearchStatus);
        if LocationCode <> '' then
            WarehouseTask.SetRange("Location Code", LocationCode);
        exit(WarehouseTask.FindFirst());
    end;

    local procedure FindMostUrgentReleased(LocationCode: Code[10]; var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    begin
        WarehouseTask.Reset();
        WarehouseTask.SetCurrentKey(Status, "Location Code", Priority, "Due Date");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHAReleased);
        if LocationCode <> '' then
            WarehouseTask.SetRange("Location Code", LocationCode);
        exit(WarehouseTask.FindFirst());
    end;

    local procedure WriteBackToDocument(var WarehouseTask: Record "WHA Warehouse Task")
    var
        Setup: Record "WHA Warehouse Task Setup";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
    begin
        Setup.SetLoadFields("Write Back To Document");
        if not Setup.Get() then
            exit;
        if not Setup."Write Back To Document" then
            exit;

        if not TaskSourceMgt.WriteBack(WarehouseTask) then
            exit;

        WarehouseTask."Written Back" := true;
        WarehouseTask.Modify(true);
    end;

    local procedure DefaultTrackingFromUnit(var WarehouseTask: Record "WHA Warehouse Task")
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        if WarehouseTask."Handling Unit No." = '' then
            exit;
        if (WarehouseTask."Lot No." <> '') or (WarehouseTask."Serial No." <> '') then
            exit;

        HandlingUnitLine.SetLoadFields("Item No.", "Lot No.", "Serial No.");
        HandlingUnitLine.SetRange("Handling Unit No.", WarehouseTask."Handling Unit No.");
        if WarehouseTask."Item No." <> '' then
            HandlingUnitLine.SetRange("Item No.", WarehouseTask."Item No.");
        if HandlingUnitLine.Count() <> 1 then
            exit;

        HandlingUnitLine.FindFirst();
        WarehouseTask."Lot No." := HandlingUnitLine."Lot No.";
        WarehouseTask."Serial No." := HandlingUnitLine."Serial No.";
    end;

    local procedure MoveHandlingUnit(var WarehouseTask: Record "WHA Warehouse Task")
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        if WarehouseTask."Handling Unit No." = '' then
            exit;
        if not HandlingUnit.Get(WarehouseTask."Handling Unit No.") then
            exit;
        if (HandlingUnit."Location Code" = WarehouseTask."Location Code") and (HandlingUnit."Bin Code" = WarehouseTask."To Bin Code") then
            exit;
        if (WarehouseTask."Location Code" = '') and (WarehouseTask."To Bin Code" = '') then
            exit;

        if WarehouseTask."Location Code" <> '' then
            HandlingUnit.Validate("Location Code", WarehouseTask."Location Code");
        if WarehouseTask."To Bin Code" <> '' then
            HandlingUnit.Validate("Bin Code", WarehouseTask."To Bin Code");
        HandlingUnit.Modify(true);
    end;

    local procedure CreateFollowUp(var WarehouseTask: Record "WHA Warehouse Task"; Outstanding: Decimal)
    var
        Setup: Record "WHA Warehouse Task Setup";
        FollowUpTask: Record "WHA Warehouse Task";
    begin
        Setup.SetLoadFields("Follow Up Short Picks");
        if not Setup.Get() then
            exit;
        if not Setup."Follow Up Short Picks" then
            exit;

        FollowUpTask.Init();
        FollowUpTask."Task Type" := WarehouseTask."Task Type";
        FollowUpTask.Description := CopyStr(StrSubstNo(FollowUpDescLbl, WarehouseTask."No."), 1, MaxStrLen(FollowUpTask.Description));
        FollowUpTask."Location Code" := WarehouseTask."Location Code";
        FollowUpTask."From Bin Code" := WarehouseTask."From Bin Code";
        FollowUpTask."To Bin Code" := WarehouseTask."To Bin Code";
        FollowUpTask."Item No." := WarehouseTask."Item No.";
        FollowUpTask."Variant Code" := WarehouseTask."Variant Code";
        FollowUpTask."Unit of Measure Code" := WarehouseTask."Unit of Measure Code";
        FollowUpTask.Quantity := Outstanding;
        FollowUpTask.Priority := WarehouseTask.Priority;
        FollowUpTask."Due Date" := WarehouseTask."Due Date";
        FollowUpTask.Insert(true);
    end;

    local procedure CheckUserTaskLimit(var WarehouseTask: Record "WHA Warehouse Task")
    var
        Setup: Record "WHA Warehouse Task Setup";
        OpenTask: Record "WHA Warehouse Task";
        OpenCount: Integer;
    begin
        Setup.SetLoadFields("Max Open Tasks Per User");
        if not Setup.Get() then
            exit;
        if Setup."Max Open Tasks Per User" <= 0 then
            exit;

        OpenTask.SetLoadFields("No.");
        OpenTask.SetCurrentKey("Assigned To User ID", Status, Priority);
        OpenTask.SetRange("Assigned To User ID", WarehouseTask."Assigned To User ID");
        OpenTask.SetFilter(Status, '%1|%2', OpenTask.Status::WHAAssigned, OpenTask.Status::WHAInProgress);
        OpenTask.SetFilter("No.", '<>%1', WarehouseTask."No.");
        OpenCount := OpenTask.Count();

        if OpenCount >= Setup."Max Open Tasks Per User" then
            Error(UserTaskLimitErr, WarehouseTask."Assigned To User ID", OpenCount);
    end;

    local procedure IsReadyForWork(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    begin
        if WarehouseTask."Location Code" = '' then
            exit(false);
        exit(HasSomethingToMove(WarehouseTask));
    end;

    local procedure HasSomethingToMove(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    begin
        if WarehouseTask."Handling Unit No." <> '' then
            exit(true);
        exit((WarehouseTask."Item No." <> '') and (WarehouseTask.Quantity > 0));
    end;

    local procedure NextTaskNo(): Code[20]
    var
        Setup: Record "WHA Warehouse Task Setup";
        NoSeries: Codeunit "No. Series";
    begin
        Setup.SetLoadFields("Warehouse Task Nos.");
        if not Setup.Get() then
            Error(NoSeriesMissingErr);
        if Setup."Warehouse Task Nos." = '' then
            Error(NoSeriesMissingErr);

        exit(NoSeries.GetNextNo(Setup."Warehouse Task Nos."));
    end;
}
