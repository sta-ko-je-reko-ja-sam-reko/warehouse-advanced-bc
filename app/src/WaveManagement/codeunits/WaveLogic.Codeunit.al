namespace WarehouseAdvanced.WaveManagement;

using Microsoft.Foundation.NoSeries;
using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.LabourManagement;

codeunit 50150 "WHA Wave Logic" implements "WHA IWave"
{
    Access = Public;

    var
        NoSeriesMissingErr: Label 'Set the wave number series on the wave setup page before creating waves.';
        NotOpenErr: Label 'Wave %1 is %2, so its work can no longer be changed.', Comment = '%1 = the wave number, %2 = the current status';
        ReleaseNotAllowedErr: Label 'Only an open wave can be released. Wave %1 is %2.', Comment = '%1 = the wave number, %2 = the current status';
        EmptyWaveErr: Label 'Wave %1 holds no work, so there is nothing to release.', Comment = '%1 = the wave number';
        LocationMissingErr: Label 'Give wave %1 a location before filling it, so it gathers work from one part of the warehouse.', Comment = '%1 = the wave number';
        NotReleasedErr: Label 'Wave %1 is %2, so it cannot be completed. Only a released wave can finish.', Comment = '%1 = the wave number, %2 = the current status';
        StillWorkingErr: Label 'Wave %1 still has %2 job(s) outstanding.', Comment = '%1 = the wave number, %2 = how many jobs are not finished';
        CancelNotAllowedErr: Label 'Wave %1 is already %2, so it cannot be cancelled.', Comment = '%1 = the wave number, %2 = the current status';
        DeleteNotAllowedErr: Label 'Wave %1 cannot be deleted while its status is %2. Cancel it instead, so the record of what was planned is kept.', Comment = '%1 = the wave number, %2 = the current status';
        AlreadyInWaveErr: Label 'Warehouse task %1 is already in wave %2.', Comment = '%1 = the warehouse task number, %2 = the wave it is already in';
        WrongLocationErr: Label 'Warehouse task %1 is at %2, and wave %3 gathers work at %4.', Comment = '%1 = the warehouse task number, %2 = the task location, %3 = the wave number, %4 = the wave location';
        TaskNotOpenErr: Label 'Warehouse task %1 is %2, so it cannot be put into a wave.', Comment = '%1 = the warehouse task number, %2 = the task status';

    /// <summary>
    /// Assigns the number from the foundation series and the defaults a new wave needs.
    /// </summary>
    /// <param name="Wave">The wave being inserted.</param>
    procedure Trigger_OnInsert(var Wave: Record "WHA Wave")
    var
        Setup: Record "WHA Wave Setup";
    begin
        if Wave."No." = '' then
            Wave."No." := NextWaveNo();

        Setup.SetLoadFields("Default Strategy", "Default Max Tasks", "Default Max Minutes");
        if not Setup.Get() then
            exit;

        if Wave.Strategy = Wave.Strategy::WHAMostUrgent then
            Wave.Strategy := Setup."Default Strategy";
        if Wave."Max Tasks" = 0 then
            Wave."Max Tasks" := Setup."Default Max Tasks";
        if Wave."Max Minutes" = 0 then
            Wave."Max Minutes" := Setup."Default Max Minutes";
    end;

    /// <summary>
    /// Refuses to delete a wave that has reached the floor, and releases the work held by one that has
    /// not, so no task is left pointing at a wave that no longer exists.
    /// </summary>
    /// <param name="Wave">The wave being deleted.</param>
    procedure Trigger_OnDelete(var Wave: Record "WHA Wave")
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        if Wave.Status in [Wave.Status::WHAReleased, Wave.Status::WHACompleted] then
            Error(DeleteNotAllowedErr, Wave."No.", Wave.Status);

        WarehouseTask.SetCurrentKey("Wave No.", Status);
        WarehouseTask.SetRange("Wave No.", Wave."No.");
        if WarehouseTask.FindSet() then
            repeat
                WarehouseTask."Wave No." := '';
                WarehouseTask.Modify(true);
            until WarehouseTask.Next() = 0;
    end;

    /// <summary>
    /// Fills an open wave with the work its strategy picks, up to the number of tasks it allows.
    /// </summary>
    /// <param name="Wave">The wave to fill.</param>
    /// <returns>How many tasks were added.</returns>
    procedure Fill(var Wave: Record "WHA Wave"): Integer
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Strategy: Interface "WHA IWaveStrategy";
        Added: Integer;
        Room: Integer;
        MinutesRoom: Decimal;
        TaskMinutes: Decimal;
    begin
        CheckOpen(Wave);
        if Wave."Location Code" = '' then
            Error(LocationMissingErr, Wave."No.");

        Room := RoomLeft(Wave);
        if Room <= 0 then
            exit(0);

        MinutesRoom := MinutesLeft(Wave);
        Added := 0;

        Strategy := Wave.Strategy;
        if not Strategy.SelectCandidates(Wave, WarehouseTask) then
            exit(0);
        if not WarehouseTask.FindSet(true) then
            exit(0);

        repeat
            TaskMinutes := TaskMinutesOf(WarehouseTask);
            if IsOverMinutes(Wave, Added, MinutesRoom, TaskMinutes) then
                exit(Added);

            WarehouseTask."Wave No." := Wave."No.";
            WarehouseTask.Modify(true);
            MinutesRoom -= TaskMinutes;
            Added += 1;
        until (Added >= Room) or (WarehouseTask.Next() = 0);

        exit(Added);
    end;

    /// <summary>
    /// Works out how long the work already in a wave should take, from the labour standards.
    /// </summary>
    /// <param name="Wave">The wave to measure.</param>
    /// <param name="Measured">Receives whether any standard applied at all.</param>
    /// <returns>The expected time in minutes.</returns>
    procedure EstimateMinutes(var Wave: Record "WHA Wave"; var Measured: Boolean): Decimal
    var
        WarehouseTask: Record "WHA Warehouse Task";
        LabourMgt: Codeunit "WHA Labour Mgt.";
        TaskMeasured: Boolean;
        Total: Decimal;
    begin
        Measured := false;

        WarehouseTask.SetLoadFields("Task Type", "Location Code", Quantity);
        WarehouseTask.SetCurrentKey("Wave No.", Status);
        WarehouseTask.SetRange("Wave No.", Wave."No.");
        if not WarehouseTask.FindSet() then
            exit(0);

        repeat
            Total += LabourMgt.ExpectedMinutes(WarehouseTask."Task Type", WarehouseTask."Location Code", PlannedQuantity(WarehouseTask), TaskMeasured);
            if TaskMeasured then
                Measured := true;
        until WarehouseTask.Next() = 0;

        exit(Total);
    end;

    /// <summary>
    /// Puts one task into a wave.
    /// </summary>
    /// <param name="Wave">The wave to add to.</param>
    /// <param name="WarehouseTask">The task to add.</param>
    procedure AddTask(var Wave: Record "WHA Wave"; var WarehouseTask: Record "WHA Warehouse Task")
    begin
        CheckOpen(Wave);

        if WarehouseTask."Wave No." = Wave."No." then
            exit;
        if WarehouseTask."Wave No." <> '' then
            Error(AlreadyInWaveErr, WarehouseTask."No.", WarehouseTask."Wave No.");
        if not IsGatherable(WarehouseTask) then
            Error(TaskNotOpenErr, WarehouseTask."No.", WarehouseTask.Status);
        if (Wave."Location Code" <> '') and (WarehouseTask."Location Code" <> Wave."Location Code") then
            Error(WrongLocationErr, WarehouseTask."No.", WarehouseTask."Location Code", Wave."No.", Wave."Location Code");

        WarehouseTask."Wave No." := Wave."No.";
        WarehouseTask.Modify(true);
    end;

    /// <summary>
    /// Takes one task back out of a wave, leaving the task itself alone.
    /// </summary>
    /// <param name="Wave">The wave to take from.</param>
    /// <param name="WarehouseTask">The task to remove.</param>
    procedure RemoveTask(var Wave: Record "WHA Wave"; var WarehouseTask: Record "WHA Warehouse Task")
    begin
        CheckOpen(Wave);

        if WarehouseTask."Wave No." <> Wave."No." then
            exit;

        WarehouseTask."Wave No." := '';
        WarehouseTask.Modify(true);
    end;

    /// <summary>
    /// Sends every job in the wave to the floor at once.
    /// </summary>
    /// <param name="Wave">The wave to release.</param>
    procedure Release(var Wave: Record "WHA Wave")
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if Wave.Status <> Wave.Status::WHAOpen then
            Error(ReleaseNotAllowedErr, Wave."No.", Wave.Status);

        WarehouseTask.SetCurrentKey("Wave No.", Status);
        WarehouseTask.SetRange("Wave No.", Wave."No.");
        if WarehouseTask.IsEmpty() then
            Error(EmptyWaveErr, Wave."No.");

        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHACreated);
        if WarehouseTask.FindSet() then
            repeat
                TaskLogic.Release(WarehouseTask);
            until WarehouseTask.Next() = 0;

        Wave.Status := Wave.Status::WHAReleased;
        Wave."Released At" := CurrentDateTime;
        Wave.Modify(true);
    end;

    /// <summary>
    /// Closes a wave whose work is all finished or withdrawn, and refuses one that still has work
    /// outstanding.
    /// </summary>
    /// <param name="Wave">The wave to complete.</param>
    procedure Complete(var Wave: Record "WHA Wave")
    var
        Outstanding: Integer;
    begin
        if Wave.Status <> Wave.Status::WHAReleased then
            Error(NotReleasedErr, Wave."No.", Wave.Status);

        Outstanding := OutstandingCount(Wave);
        if Outstanding > 0 then
            Error(StillWorkingErr, Wave."No.", Outstanding);

        CloseWave(Wave);
    end;

    /// <summary>
    /// Closes a wave that is finished, and does nothing to one that is not.
    /// </summary>
    /// <param name="Wave">The wave to look at.</param>
    /// <returns>True when the wave was closed by this call.</returns>
    procedure CompleteIfFinished(var Wave: Record "WHA Wave"): Boolean
    begin
        if Wave.Status <> Wave.Status::WHAReleased then
            exit(false);
        if OutstandingCount(Wave) > 0 then
            exit(false);

        CloseWave(Wave);
        exit(true);
    end;

    /// <summary>
    /// Withdraws a wave, cancelling any of its work that has not been started.
    /// </summary>
    /// <param name="Wave">The wave to cancel.</param>
    procedure Cancel(var Wave: Record "WHA Wave")
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if Wave.Status in [Wave.Status::WHACompleted, Wave.Status::WHACancelled] then
            Error(CancelNotAllowedErr, Wave."No.", Wave.Status);

        WarehouseTask.SetCurrentKey("Wave No.", Status);
        WarehouseTask.SetRange("Wave No.", Wave."No.");
        WarehouseTask.SetFilter(Status, '%1|%2', WarehouseTask.Status::WHACreated, WarehouseTask.Status::WHAReleased);
        if WarehouseTask.FindSet() then
            repeat
                TaskLogic.Cancel(WarehouseTask);
            until WarehouseTask.Next() = 0;

        Wave.Status := Wave.Status::WHACancelled;
        Wave.Modify(true);
    end;

    local procedure CloseWave(var Wave: Record "WHA Wave")
    begin
        Wave.Status := Wave.Status::WHACompleted;
        Wave."Completed At" := CurrentDateTime;
        Wave.Modify(true);
    end;

    local procedure OutstandingCount(var Wave: Record "WHA Wave"): Integer
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetLoadFields("No.");
        WarehouseTask.SetCurrentKey("Wave No.", Status);
        WarehouseTask.SetRange("Wave No.", Wave."No.");
        WarehouseTask.SetFilter(Status, '<>%1&<>%2', WarehouseTask.Status::WHACompleted, WarehouseTask.Status::WHACancelled);
        exit(WarehouseTask.Count());
    end;

    local procedure RoomLeft(var Wave: Record "WHA Wave"): Integer
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        if Wave."Max Tasks" <= 0 then
            exit(MaxUnlimited());

        WarehouseTask.SetLoadFields("No.");
        WarehouseTask.SetCurrentKey("Wave No.", Status);
        WarehouseTask.SetRange("Wave No.", Wave."No.");
        exit(Wave."Max Tasks" - WarehouseTask.Count());
    end;

    local procedure MinutesLeft(var Wave: Record "WHA Wave"): Decimal
    var
        Measured: Boolean;
    begin
        if Wave."Max Minutes" <= 0 then
            exit(0);
        exit(Wave."Max Minutes" - EstimateMinutes(Wave, Measured));
    end;

    local procedure IsOverMinutes(var Wave: Record "WHA Wave"; Added: Integer; MinutesRoom: Decimal; TaskMinutes: Decimal): Boolean
    begin
        if Wave."Max Minutes" <= 0 then
            exit(false);
        if TaskMinutes <= 0 then
            exit(false);
        if TaskMinutes <= MinutesRoom then
            exit(false);

        exit(Added > 0);
    end;

    local procedure TaskMinutesOf(var WarehouseTask: Record "WHA Warehouse Task"): Decimal
    var
        LabourMgt: Codeunit "WHA Labour Mgt.";
        Measured: Boolean;
    begin
        exit(LabourMgt.ExpectedMinutes(WarehouseTask."Task Type", WarehouseTask."Location Code", PlannedQuantity(WarehouseTask), Measured));
    end;

    local procedure PlannedQuantity(var WarehouseTask: Record "WHA Warehouse Task"): Decimal
    begin
        if WarehouseTask.Quantity > 0 then
            exit(WarehouseTask.Quantity);
        exit(1);
    end;

    local procedure IsGatherable(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    begin
        exit(WarehouseTask.Status in [WarehouseTask.Status::WHACreated, WarehouseTask.Status::WHAReleased]);
    end;

    local procedure CheckOpen(var Wave: Record "WHA Wave")
    begin
        if Wave.Status <> Wave.Status::WHAOpen then
            Error(NotOpenErr, Wave."No.", Wave.Status);
    end;

    local procedure MaxUnlimited(): Integer
    begin
        exit(10000);
    end;

    local procedure NextWaveNo(): Code[20]
    var
        Setup: Record "WHA Wave Setup";
        NoSeries: Codeunit "No. Series";
    begin
        Setup.SetLoadFields("Wave Nos.");
        if not Setup.Get() then
            Error(NoSeriesMissingErr);
        if Setup."Wave Nos." = '' then
            Error(NoSeriesMissingErr);

        exit(NoSeries.GetNextNo(Setup."Wave Nos."));
    end;
}
