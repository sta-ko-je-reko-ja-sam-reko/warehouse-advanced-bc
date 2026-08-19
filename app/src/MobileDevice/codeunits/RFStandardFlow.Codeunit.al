namespace WarehouseAdvanced.MobileDevice;

using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;

codeunit 50100 "WHA RF Standard Flow" implements "WHA IRFFlow"
{
    Access = Public;

    var
        DeviceRequiredErr: Label 'Scan the code on your handheld before asking for work.';
        UnknownDeviceErr: Label 'Handheld %1 is not registered. Ask your supervisor to register it.', Comment = '%1 = the device code that was scanned';
        DeviceBlockedErr: Label 'Handheld %1 is blocked and cannot be used.', Comment = '%1 = the device code that was scanned';
        WrongBinErr: Label 'You scanned %1. Go to bin %2.', Comment = '%1 = what was scanned, %2 = the bin the job is for';
        WrongUnitErr: Label 'You scanned %1. This job is for handling unit %2.', Comment = '%1 = what was scanned, %2 = the handling unit the job is for';
        NothingToScanErr: Label 'There is nothing to scan now. Read the screen and choose the action it asks for.';
        NotReadyErr: Label 'Finish the steps on the screen before confirming.';
        NoTaskErr: Label 'You are not holding a job. Choose Next task first.';
        SignInLbl: Label 'Scan the code on your handheld to sign in.';
        GetWorkLbl: Label 'Choose Next task when you are ready for the next job.';
        ScanFromLbl: Label 'Go to bin %1 and scan it.', Comment = '%1 = the bin to take from';
        ScanUnitLbl: Label 'Scan handling unit %1.', Comment = '%1 = the handling unit to scan';
        ScanToLbl: Label 'Put it in bin %1 and scan it.', Comment = '%1 = the bin to put into';
        ConfirmLbl: Label 'Confirm to finish job %1.', Comment = '%1 = the warehouse task number';
        ShortPickLbl: Label 'The job asks for %1. Enter how many you found, and why the rest is missing.', Comment = '%1 = the quantity the job asked for';
        NotCountedErr: Label 'This job does not move a counted quantity, so there is nothing to be short of. Hand it back instead.';

    /// <summary>
    /// Establishes which device the operator is working on, and refuses one that is unknown or blocked.
    /// </summary>
    /// <param name="DeviceCode">The code scanned or typed on the handheld.</param>
    /// <param name="RFDevice">Receives the device. Left blank when unregistered devices are allowed.</param>
    procedure SignIn(DeviceCode: Code[20]; var RFDevice: Record "WHA RF Device")
    var
        Setup: Record "WHA RF Setup";
        DeviceRequired: Boolean;
    begin
        Clear(RFDevice);

        Setup.SetLoadFields("Require Device Registration");
        if Setup.Get() then
            DeviceRequired := Setup."Require Device Registration";

        if DeviceCode = '' then begin
            if DeviceRequired then
                Error(DeviceRequiredErr);
            exit;
        end;

        if not RFDevice.Get(DeviceCode) then begin
            if DeviceRequired then
                Error(UnknownDeviceErr, DeviceCode);
            exit;
        end;

        if RFDevice.Blocked then
            Error(DeviceBlockedErr, DeviceCode);

        RFDevice."Last User ID" := CopyStr(UserId(), 1, MaxStrLen(RFDevice."Last User ID"));
        RFDevice."Last Seen At" := CurrentDateTime;
        RFDevice.Modify(true);
    end;

    /// <summary>
    /// Hands the operator the work they should do next, at the location the device belongs to.
    /// </summary>
    /// <param name="RFDevice">The device the operator is working on.</param>
    /// <param name="WarehouseTask">Receives the task to work.</param>
    /// <returns>True when there is work to do.</returns>
    procedure NextTask(var RFDevice: Record "WHA RF Device"; var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        Setup: Record "WHA RF Setup";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if not TaskLogic.GetNextForUser(CopyStr(UserId(), 1, MaxStrLen(WarehouseTask."Assigned To User ID")), RFDevice."Default Location Code", WarehouseTask) then
            exit(false);

        Setup.SetLoadFields("Auto Start Task");
        if Setup.Get() then
            if Setup."Auto Start Task" then
                if WarehouseTask.Status = WarehouseTask.Status::WHAAssigned then
                    TaskLogic.Start(WarehouseTask);

        exit(true);
    end;

    /// <summary>
    /// Decides where a task starts on the handheld, which depends on what the task actually names.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <returns>The step to show first.</returns>
    procedure FirstStep(var WarehouseTask: Record "WHA Warehouse Task"): Enum "WHA RF Step"
    var
        Step: Enum "WHA RF Step";
    begin
        if not ConfirmByScan() then
            exit(Step::WHAConfirm);

        if WarehouseTask."From Bin Code" <> '' then
            exit(Step::WHAScanFrom);

        exit(AfterFromBin(WarehouseTask));
    end;

    /// <summary>
    /// Checks what the operator scanned against what the current step asked for, and answers with the
    /// step that follows.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <param name="CurrentStep">The step the operator is on.</param>
    /// <param name="ScannedValue">What came off the scanner.</param>
    /// <returns>The next step.</returns>
    procedure Scan(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"; ScannedValue: Text): Enum "WHA RF Step"
    var
        Step: Enum "WHA RF Step";
        Scanned: Code[50];
    begin
        Scanned := Normalise(ScannedValue);

        case CurrentStep of
            Step::WHAScanFrom:
                begin
                    if Scanned <> Normalise(WarehouseTask."From Bin Code") then
                        Error(WrongBinErr, Scanned, WarehouseTask."From Bin Code");
                    exit(AfterFromBin(WarehouseTask));
                end;
            Step::WHAScanUnit:
                begin
                    if not IsTheUnit(WarehouseTask, Scanned) then
                        Error(WrongUnitErr, Scanned, WarehouseTask."Handling Unit No.");
                    exit(AfterUnit(WarehouseTask));
                end;
            Step::WHAScanTo:
                begin
                    if Scanned <> Normalise(WarehouseTask."To Bin Code") then
                        Error(WrongBinErr, Scanned, WarehouseTask."To Bin Code");
                    exit(Step::WHAConfirm);
                end;
        end;

        Error(NothingToScanErr);
    end;

    /// <summary>
    /// The line of text the operator reads.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <param name="CurrentStep">The step the operator is on.</param>
    /// <returns>What to do next, in the operator's language.</returns>
    procedure Instruction(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"): Text
    var
        Step: Enum "WHA RF Step";
    begin
        case CurrentStep of
            Step::WHASignIn:
                exit(SignInLbl);
            Step::WHAGetWork:
                exit(GetWorkLbl);
            Step::WHAScanFrom:
                exit(StrSubstNo(ScanFromLbl, WarehouseTask."From Bin Code"));
            Step::WHAScanUnit:
                exit(StrSubstNo(ScanUnitLbl, WarehouseTask."Handling Unit No."));
            Step::WHAScanTo:
                exit(StrSubstNo(ScanToLbl, WarehouseTask."To Bin Code"));
            Step::WHAConfirm:
                exit(StrSubstNo(ConfirmLbl, WarehouseTask."No."));
            Step::WHAShortPick:
                exit(StrSubstNo(ShortPickLbl, WarehouseTask.Quantity));
        end;

        exit(GetWorkLbl);
    end;

    /// <summary>
    /// Finishes the task the operator is holding and returns them to asking for work.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <param name="CurrentStep">The step the operator is on.</param>
    /// <returns>The step to show next.</returns>
    procedure Confirm(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"): Enum "WHA RF Step"
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        Step: Enum "WHA RF Step";
    begin
        if WarehouseTask."No." = '' then
            Error(NoTaskErr);
        if CurrentStep <> Step::WHAConfirm then
            Error(NotReadyErr);

        if WarehouseTask.Status = WarehouseTask.Status::WHAAssigned then
            TaskLogic.Start(WarehouseTask);

        TaskLogic.Complete(WarehouseTask);
        exit(Step::WHAGetWork);
    end;

    /// <summary>
    /// Moves the operator to reporting that there was less on the shelf than the job asked for.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <param name="CurrentStep">The step the operator is on.</param>
    /// <returns>The step to show next.</returns>
    procedure StartShortPick(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"): Enum "WHA RF Step"
    var
        Step: Enum "WHA RF Step";
    begin
        if WarehouseTask."No." = '' then
            Error(NoTaskErr);
        if WarehouseTask.Quantity <= 0 then
            Error(NotCountedErr);

        exit(Step::WHAShortPick);
    end;

    /// <summary>
    /// Finishes the job with what the operator actually found, and says why the rest is missing.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <param name="HandledQuantity">How much was actually moved.</param>
    /// <param name="Reason">Why the rest was not.</param>
    /// <returns>The step to show next.</returns>
    procedure ShortPick(var WarehouseTask: Record "WHA Warehouse Task"; HandledQuantity: Decimal; Reason: Enum "WHA Whse. Short Reason"): Enum "WHA RF Step"
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        Step: Enum "WHA RF Step";
    begin
        if WarehouseTask."No." = '' then
            Error(NoTaskErr);

        if WarehouseTask.Status = WarehouseTask.Status::WHAAssigned then
            TaskLogic.Start(WarehouseTask);

        TaskLogic.CompleteShort(WarehouseTask, HandledQuantity, Reason);
        exit(Step::WHAGetWork);
    end;

    /// <summary>
    /// Gives the task back to the queue, for when the operator cannot finish it.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <returns>The step to show next.</returns>
    procedure HandBack(var WarehouseTask: Record "WHA Warehouse Task"): Enum "WHA RF Step"
    var
        Step: Enum "WHA RF Step";
    begin
        if WarehouseTask."No." = '' then
            Error(NoTaskErr);

        WarehouseTask.Validate("Assigned To User ID", '');
        WarehouseTask.Modify(true);
        exit(Step::WHAGetWork);
    end;

    local procedure AfterFromBin(var WarehouseTask: Record "WHA Warehouse Task"): Enum "WHA RF Step"
    var
        Step: Enum "WHA RF Step";
    begin
        if WarehouseTask."Handling Unit No." <> '' then
            exit(Step::WHAScanUnit);
        exit(AfterUnit(WarehouseTask));
    end;

    local procedure AfterUnit(var WarehouseTask: Record "WHA Warehouse Task"): Enum "WHA RF Step"
    var
        Step: Enum "WHA RF Step";
    begin
        if WarehouseTask."To Bin Code" <> '' then
            exit(Step::WHAScanTo);
        exit(Step::WHAConfirm);
    end;

    local procedure IsTheUnit(var WarehouseTask: Record "WHA Warehouse Task"; Scanned: Code[50]): Boolean
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        if Scanned = Normalise(WarehouseTask."Handling Unit No.") then
            exit(true);

        HandlingUnit.SetLoadFields(SSCC);
        if not HandlingUnit.Get(WarehouseTask."Handling Unit No.") then
            exit(false);

        exit((HandlingUnit.SSCC <> '') and (Scanned = Normalise(HandlingUnit.SSCC)));
    end;

    local procedure ConfirmByScan(): Boolean
    var
        Setup: Record "WHA RF Setup";
    begin
        Setup.SetLoadFields("Confirm By Scan");
        if not Setup.Get() then
            exit(true);
        exit(Setup."Confirm By Scan");
    end;

    local procedure Normalise(Value: Text): Code[50]
    begin
        exit(CopyStr(UpperCase(DelChr(Value, '<>', ' ')), 1, 50));
    end;
}
