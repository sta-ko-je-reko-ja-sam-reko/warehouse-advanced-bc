namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using System.IO;
using System.Security.AccessControl;
using WarehouseAdvanced.HandlingUnit;

codeunit 50203 "WHA Demo Warehouse Task"
{
    Access = Public;

    var
        DemoLocationCode: Code[10];
        DemoFromBinCode: Code[20];
        DemoToBinCode: Code[20];
        DemoItemNo: Code[20];
        DemoUnitNo: Code[20];
        DemoUserId: Code[50];
        PackageCodeTok: Label 'WHA-TASK', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Directed Work';
        PutAwayDescLbl: Label 'Put the received pallet away';
        PickDescLbl: Label 'Pick for the afternoon shipment';
        MovementDescLbl: Label 'Move stock to the pick face';
        ReplenishmentDescLbl: Label 'Replenish the fast-moving bin';
        CountDescLbl: Label 'Count the bin before the shift ends';
        CancelledDescLbl: Label 'Pick for an order that was withdrawn';

    /// <summary>
    /// Seeds sample warehouse tasks that exercise every task type, every status, both ways of saying what
    /// is moved, priority, due dates and assignment. Idempotent — re-running creates nothing new. Also
    /// builds this feature's RapidStart configuration package, so the package exists only when the user
    /// chose to import sample data.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Warehouse Task Setup";
        TaskFeatureSetup: Codeunit "WHA Task Feature Setup";
    begin
        TaskFeatureSetup.EnsureSetup(Setup);

        ResolveContext();

        CreatePutAwayTask();
        CreatePickTask();
        CreateMovementTask();
        CreateReplenishmentTask();
        CreateCountTask();
        CreateCancelledTask();

        CreateConfigPackage();
    end;

    local procedure ResolveContext()
    begin
        DemoLocationCode := FirstLocation();
        ResolveBins();
        DemoItemNo := FirstItem();
        DemoUnitNo := FirstDemoHandlingUnit();
        DemoUserId := CurrentUserIfKnown();
    end;

    local procedure CreatePutAwayTask()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskType: Enum "WHA Warehouse Task Type";
    begin
        if not PrepareTask(WarehouseTask, 'DEMO-TASK-001', TaskType::WHAPutAway, PutAwayDescLbl, 50) then
            exit;

        ApplyHandlingUnitOrItem(WarehouseTask, 6);
        if DemoToBinCode <> '' then
            WarehouseTask.Validate("To Bin Code", DemoToBinCode);
        WarehouseTask.Insert(true);
    end;

    local procedure CreatePickTask()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskType: Enum "WHA Warehouse Task Type";
        Status: Enum "WHA Warehouse Task Status";
    begin
        if not PrepareTask(WarehouseTask, 'DEMO-TASK-002', TaskType::WHAPick, PickDescLbl, 10) then
            exit;

        ApplyItem(WarehouseTask, 4);
        WarehouseTask.Validate("Due Date", WorkDate());
        WarehouseTask.Insert(true);

        DriveToStatus(WarehouseTask, Status::WHAReleased);
    end;

    local procedure CreateMovementTask()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskType: Enum "WHA Warehouse Task Type";
        Status: Enum "WHA Warehouse Task Status";
    begin
        if not PrepareTask(WarehouseTask, 'DEMO-TASK-003', TaskType::WHAMovement, MovementDescLbl, 100) then
            exit;

        ApplyItem(WarehouseTask, 12);
        WarehouseTask.Insert(true);

        DriveToStatus(WarehouseTask, Status::WHAAssigned);
    end;

    local procedure CreateReplenishmentTask()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskType: Enum "WHA Warehouse Task Type";
        Status: Enum "WHA Warehouse Task Status";
    begin
        if not PrepareTask(WarehouseTask, 'DEMO-TASK-004', TaskType::WHAReplenishment, ReplenishmentDescLbl, 20) then
            exit;

        ApplyItem(WarehouseTask, 24);
        WarehouseTask.Insert(true);

        DriveToStatus(WarehouseTask, Status::WHAInProgress);
    end;

    local procedure CreateCountTask()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskType: Enum "WHA Warehouse Task Type";
        Status: Enum "WHA Warehouse Task Status";
    begin
        if not PrepareTask(WarehouseTask, 'DEMO-TASK-005', TaskType::WHACount, CountDescLbl, 0) then
            exit;

        ApplyItem(WarehouseTask, 1);
        WarehouseTask.Insert(true);

        DriveToStatus(WarehouseTask, Status::WHACompleted);
    end;

    local procedure CreateCancelledTask()
    var
        WarehouseTask: Record "WHA Warehouse Task";
        TaskType: Enum "WHA Warehouse Task Type";
        Status: Enum "WHA Warehouse Task Status";
    begin
        if not PrepareTask(WarehouseTask, 'DEMO-TASK-006', TaskType::WHAPick, CancelledDescLbl, 100) then
            exit;

        ApplyItem(WarehouseTask, 3);
        WarehouseTask.Insert(true);

        DriveToStatus(WarehouseTask, Status::WHACancelled);
    end;

    local procedure PrepareTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20]; TaskType: Enum "WHA Warehouse Task Type"; TaskDescription: Text[100]; TaskPriority: Integer): Boolean
    begin
        if WarehouseTask.Get(TaskNo) then
            exit(false);

        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask.Validate("Task Type", TaskType);
        WarehouseTask.Validate(Description, TaskDescription);
        WarehouseTask.Validate(Priority, TaskPriority);
        if DemoLocationCode <> '' then
            WarehouseTask.Validate("Location Code", DemoLocationCode);
        if DemoFromBinCode <> '' then
            WarehouseTask.Validate("From Bin Code", DemoFromBinCode);
        exit(true);
    end;

    local procedure ApplyHandlingUnitOrItem(var WarehouseTask: Record "WHA Warehouse Task"; Qty: Decimal)
    begin
        if DemoUnitNo <> '' then begin
            WarehouseTask.Validate("Handling Unit No.", DemoUnitNo);
            exit;
        end;

        ApplyItem(WarehouseTask, Qty);
    end;

    local procedure ApplyItem(var WarehouseTask: Record "WHA Warehouse Task"; Qty: Decimal)
    begin
        if DemoItemNo = '' then
            exit;

        WarehouseTask.Validate("Item No.", DemoItemNo);
        WarehouseTask.Validate(Quantity, Qty);
    end;

    local procedure DriveToStatus(var WarehouseTask: Record "WHA Warehouse Task"; TargetStatus: Enum "WHA Warehouse Task Status")
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if TargetStatus = TargetStatus::WHACancelled then begin
            TaskLogic.Cancel(WarehouseTask);
            exit;
        end;

        if WarehouseTask.Status = WarehouseTask.Status::WHACreated then
            if not TryRelease(WarehouseTask) then
                exit;

        if TargetStatus = TargetStatus::WHAReleased then
            exit;
        if DemoUserId = '' then
            exit;

        if WarehouseTask.Status = WarehouseTask.Status::WHAReleased then
            TaskLogic.Assign(WarehouseTask, DemoUserId);
        if TargetStatus = TargetStatus::WHAAssigned then
            exit;

        if WarehouseTask.Status = WarehouseTask.Status::WHAAssigned then
            TaskLogic.Start(WarehouseTask);
        if TargetStatus = TargetStatus::WHAInProgress then
            exit;

        if WarehouseTask.Status = WarehouseTask.Status::WHAInProgress then
            TaskLogic.Complete(WarehouseTask);
    end;

    local procedure TryRelease(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if WarehouseTask."Location Code" = '' then
            exit(false);
        if (WarehouseTask."Handling Unit No." = '') and (WarehouseTask."Item No." = '') then
            exit(false);

        TaskLogic.Release(WarehouseTask);
        exit(true);
    end;

    local procedure FirstLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetLoadFields(Code);
        Location.SetRange("Use As In-Transit", false);
        if not Location.FindFirst() then
            exit('');
        exit(Location.Code);
    end;

    local procedure ResolveBins()
    var
        Bin: Record Bin;
    begin
        DemoFromBinCode := '';
        DemoToBinCode := '';
        if DemoLocationCode = '' then
            exit;

        Bin.SetLoadFields(Code);
        Bin.SetRange("Location Code", DemoLocationCode);
        if not Bin.FindSet() then
            exit;

        DemoFromBinCode := Bin.Code;
        if Bin.Next() = 0 then
            exit;
        DemoToBinCode := Bin.Code;
    end;

    local procedure FirstItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("No.");
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetRange(Blocked, false);
        if not Item.FindFirst() then
            exit('');
        exit(Item."No.");
    end;

    local procedure FirstDemoHandlingUnit(): Code[20]
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        HandlingUnit.SetLoadFields("No.");
        HandlingUnit.SetRange(Status, HandlingUnit.Status::WHAOpen);
        HandlingUnit.SetFilter("No.", 'DEMO-HU-*');
        if not HandlingUnit.FindFirst() then
            exit('');
        exit(HandlingUnit."No.");
    end;

    local procedure CurrentUserIfKnown(): Code[50]
    var
        User: Record User;
        CurrentUserName: Code[50];
    begin
        CurrentUserName := CopyStr(UserId(), 1, MaxStrLen(CurrentUserName));
        if CurrentUserName = '' then
            exit('');

        User.SetLoadFields("User Name");
        User.SetRange("User Name", CurrentUserName);
        if User.IsEmpty() then
            exit('');
        exit(CurrentUserName);
    end;

    local procedure CreateConfigPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        if ConfigPackage.Get(PackageCodeTok) then
            exit;

        ConfigPackageMgt.InsertPackage(ConfigPackage, PackageCodeTok, CopyStr(PackageNameLbl, 1, 50), true);
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Warehouse Task");
    end;
}
