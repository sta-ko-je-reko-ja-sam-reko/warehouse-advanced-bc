namespace WarehouseAdvanced.DockYard;

using Microsoft.Inventory.Location;
using System.IO;

codeunit 50454 "WHA Demo Dock"
{
    Access = Public;

    var
        PackageCodeTok: Label 'WHA-DOCK', Locked = true;
        PackageNameLbl: Label 'Warehouse Advanced - Dock and Yard';
        InboundDoorTok: Label 'DOCK-IN-1', Locked = true;
        OutboundDoorTok: Label 'DOCK-OUT-1', Locked = true;
        AnyDoorTok: Label 'DOCK-FLEX-1', Locked = true;
        InboundDoorLbl: Label 'Goods in, nearest the receiving office';
        OutboundDoorLbl: Label 'Goods out, alongside the marshalling area';
        AnyDoorLbl: Label 'Takes whatever turns up';
        FirstPositionTok: Label 'YARD-01', Locked = true;
        SecondPositionTok: Label 'YARD-02', Locked = true;
        FirstPositionLbl: Label 'First bay past the gate';
        SecondPositionLbl: Label 'Second bay past the gate';
        InboundReferenceTok: Label 'WHA-DEMO-IN', Locked = true;
        OutboundReferenceTok: Label 'WHA-DEMO-OUT', Locked = true;
        InboundCarrierLbl: Label 'Sample haulier - inbound';
        OutboundCarrierLbl: Label 'Sample haulier - outbound';
        InboundTrailerTok: Label 'TR-1001', Locked = true;
        OutboundTrailerTok: Label 'TR-2002', Locked = true;

    /// <summary>
    /// Seeds three doors, two yard positions and two bookings at the first location the company has, so
    /// that every field, enum value and relation the feature ships is represented. Idempotent - the doors
    /// and positions are keyed, and a booking is recognised by the reference it carries. Also builds this
    /// feature's RapidStart configuration package.
    /// </summary>
    procedure Import()
    var
        Setup: Record "WHA Dock Setup";
        DockFeatureSetup: Codeunit "WHA Dock Feature Setup";
        LocationCode: Code[10];
    begin
        DockFeatureSetup.EnsureSetup(Setup);

        LocationCode := FirstLocation();
        if LocationCode <> '' then begin
            CreatePositions(LocationCode);
            CreateDoors(LocationCode);
            CreateAppointments(LocationCode);
        end;

        CreateConfigPackage();
    end;

    local procedure CreateDoors(LocationCode: Code[10])
    var
        Direction: Enum "WHA Door Direction";
    begin
        EnsureDoor(LocationCode, CopyStr(InboundDoorTok, 1, 20), InboundDoorLbl, Direction::WHAInbound, CopyStr(FirstPositionTok, 1, 20));
        EnsureDoor(LocationCode, CopyStr(OutboundDoorTok, 1, 20), OutboundDoorLbl, Direction::WHAOutbound, CopyStr(SecondPositionTok, 1, 20));
        EnsureDoor(LocationCode, CopyStr(AnyDoorTok, 1, 20), AnyDoorLbl, Direction::WHABoth, '');
    end;

    local procedure CreatePositions(LocationCode: Code[10])
    begin
        EnsurePosition(LocationCode, CopyStr(FirstPositionTok, 1, 20), FirstPositionLbl);
        EnsurePosition(LocationCode, CopyStr(SecondPositionTok, 1, 20), SecondPositionLbl);
    end;

    local procedure CreateAppointments(LocationCode: Code[10])
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
        AppointmentNo: Code[20];
    begin
        if not HasAppointment(CopyStr(InboundReferenceTok, 1, 50)) then begin
            AppointmentNo := DockMgt.Book(LocationCode, Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InboundDoorTok, 1, 20));
            DockAppointment.Get(AppointmentNo);
            DockAppointment."Carrier Name" := CopyStr(InboundCarrierLbl, 1, MaxStrLen(DockAppointment."Carrier Name"));
            DockAppointment."Trailer No." := CopyStr(InboundTrailerTok, 1, MaxStrLen(DockAppointment."Trailer No."));
            DockAppointment.Reference := CopyStr(InboundReferenceTok, 1, MaxStrLen(DockAppointment.Reference));
            DockAppointment.Modify(true);

            DockMgt.Arrive(DockAppointment, CopyStr(FirstPositionTok, 1, 20));
            DockMgt.MoveToDoor(DockAppointment);
            DockMgt.Depart(DockAppointment);
        end;

        if HasAppointment(CopyStr(OutboundReferenceTok, 1, 50)) then
            exit;

        AppointmentNo := DockMgt.Book(LocationCode, Direction::WHAOutbound, CreateDateTime(WorkDate(), 140000T), CopyStr(OutboundDoorTok, 1, 20));
        DockAppointment.Get(AppointmentNo);
        DockAppointment."Carrier Name" := CopyStr(OutboundCarrierLbl, 1, MaxStrLen(DockAppointment."Carrier Name"));
        DockAppointment."Trailer No." := CopyStr(OutboundTrailerTok, 1, MaxStrLen(DockAppointment."Trailer No."));
        DockAppointment.Reference := CopyStr(OutboundReferenceTok, 1, MaxStrLen(DockAppointment.Reference));
        DockAppointment.Modify(true);
    end;

    local procedure EnsureDoor(LocationCode: Code[10]; DoorCode: Code[20]; DoorDescription: Text; Direction: Enum "WHA Door Direction"; WaitingPosition: Code[20])
    var
        DockDoor: Record "WHA Dock Door";
    begin
        if DockDoor.Get(LocationCode, DoorCode) then
            exit;

        DockDoor.Init();
        DockDoor."Location Code" := LocationCode;
        DockDoor."Code" := DoorCode;
        DockDoor.Description := CopyStr(DoorDescription, 1, MaxStrLen(DockDoor.Description));
        DockDoor.Direction := Direction;
        DockDoor.Blocked := false;
        DockDoor."Yard Position Code" := WaitingPosition;
        DockDoor.Insert(true);
    end;

    local procedure EnsurePosition(LocationCode: Code[10]; PositionCode: Code[20]; PositionDescription: Text)
    var
        YardPosition: Record "WHA Yard Position";
    begin
        if YardPosition.Get(LocationCode, PositionCode) then
            exit;

        YardPosition.Init();
        YardPosition."Location Code" := LocationCode;
        YardPosition."Code" := PositionCode;
        YardPosition.Description := CopyStr(PositionDescription, 1, MaxStrLen(YardPosition.Description));
        YardPosition.Blocked := false;
        YardPosition.Insert(true);
    end;

    local procedure HasAppointment(ReferenceText: Text[50]): Boolean
    var
        DockAppointment: Record "WHA Dock Appointment";
    begin
        DockAppointment.SetRange(Reference, ReferenceText);
        exit(not DockAppointment.IsEmpty());
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

    local procedure CreateConfigPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        if ConfigPackage.Get(PackageCodeTok) then
            exit;

        ConfigPackageMgt.InsertPackage(ConfigPackage, PackageCodeTok, CopyStr(PackageNameLbl, 1, 50), true);
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Dock Door");
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Yard Position");
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, PackageCodeTok, Database::"WHA Dock Appointment");
    end;
}
