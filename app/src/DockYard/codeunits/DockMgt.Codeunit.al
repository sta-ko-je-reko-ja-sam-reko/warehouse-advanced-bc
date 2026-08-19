namespace WarehouseAdvanced.DockYard;

codeunit 50450 "WHA Dock Mgt."
{
    Access = Public;

    var
        LocationMissingErr: Label 'Say which site the vehicle is coming to. Doors and yard positions belong to one site, so a booking without one cannot be given either.';
        ExpectedAtMissingErr: Label 'Say when the vehicle is expected. A booking without a time is not a booking, and nothing can be measured against it.';
        DoorNotFoundErr: Label 'There is no door %1 at %2.', Comment = '%1 = the door code, %2 = the location code';
        DoorBlockedErr: Label 'Door %1 is blocked, so nothing new can be booked onto it.', Comment = '%1 = the door code';
        DoorDirectionErr: Label 'Door %1 does not take %2 vehicles.', Comment = '%1 = the door code, %2 = the direction of the appointment';
        DoorTakenErr: Label 'Door %1 is already booked for appointment %2 at a time that overlaps this one.', Comment = '%1 = the door code, %2 = the number of the appointment already holding the slot';
        DoorOccupiedErr: Label 'Appointment %1 is standing at door %2 right now, so nothing else can be put on it.', Comment = '%1 = the number of the appointment at the door, %2 = the door code';
        NoDoorFreeErr: Label 'No door at %1 can take appointment %2. Free one, unblock one, or move the booking.', Comment = '%1 = the location code, %2 = the appointment number';
        NotBookedErr: Label 'Appointment %1 is %2, so it cannot be checked in. Only a booked vehicle arrives.', Comment = '%1 = the appointment number, %2 = the current status';
        NotOnSiteErr: Label 'Appointment %1 is %2, so it cannot be put on a door. A vehicle has to be on site first.', Comment = '%1 = the appointment number, %2 = the current status';
        NotHereErr: Label 'Appointment %1 is %2, so it cannot leave. Only a vehicle that is on site can.', Comment = '%1 = the appointment number, %2 = the current status';
        CancelNotAllowedErr: Label 'Appointment %1 is %2, so it cannot be called off.', Comment = '%1 = the appointment number, %2 = the current status';
        FinishedErr: Label 'Appointment %1 is %2, so its door can no longer be changed.', Comment = '%1 = the appointment number, %2 = the current status';
        PositionRequiredErr: Label 'Give appointment %1 a yard position. This site parks waiting vehicles somewhere named, so that somebody can find the trailer again.', Comment = '%1 = the appointment number';
        PositionNotFoundErr: Label 'There is no yard position %1 at %2.', Comment = '%1 = the yard position code, %2 = the location code';
        PositionBlockedErr: Label 'Yard position %1 is blocked, so nothing can be parked in it.', Comment = '%1 = the yard position code';
        PositionTakenErr: Label 'Yard position %1 already has appointment %2 standing in it.', Comment = '%1 = the yard position code, %2 = the number of the appointment occupying it';

    /// <summary>
    /// Books a vehicle in. When no door is named, the configured strategy chooses one; when no door at
    /// the site can take it, the booking is still made without a door rather than refused, because a
    /// yard that cannot record a promise it has already given is worse than one with an open question
    /// on it.
    /// </summary>
    /// <param name="LocationCode">The site the vehicle is coming to. Required.</param>
    /// <param name="Direction">Whether the vehicle brings goods in or takes them out.</param>
    /// <param name="ExpectedAt">When the vehicle is expected. Required.</param>
    /// <param name="DoorCode">The door to use, or blank to have one chosen.</param>
    /// <returns>The number of the booking that was made.</returns>
    procedure Book(LocationCode: Code[10]; Direction: Enum "WHA Dock Direction"; ExpectedAt: DateTime; DoorCode: Code[20]): Code[20]
    var
        DockAppointment: Record "WHA Dock Appointment";
    begin
        if LocationCode = '' then
            Error(LocationMissingErr);
        if ExpectedAt = 0DT then
            Error(ExpectedAtMissingErr);

        DockAppointment.Init();
        DockAppointment."Location Code" := LocationCode;
        DockAppointment.Direction := Direction;
        DockAppointment."Expected At" := ExpectedAt;
        DockAppointment.Insert(true);

        AssignDoor(DockAppointment, DoorCode);
        exit(DockAppointment."No.");
    end;

    /// <summary>
    /// Puts a booking on a door, or takes the door away. A blank door code asks the configured strategy
    /// to choose, and leaves the booking without one when nothing fits.
    /// </summary>
    /// <param name="DockAppointment">The booking to change.</param>
    /// <param name="DoorCode">The door to use, or blank to have one chosen.</param>
    procedure AssignDoor(var DockAppointment: Record "WHA Dock Appointment"; DoorCode: Code[20])
    var
        Chosen: Code[20];
    begin
        CheckChangeable(DockAppointment);

        if DoorCode = '' then
            Chosen := ChooseDoor(DockAppointment)
        else begin
            CheckDoorUsable(DockAppointment, DoorCode);
            Chosen := DoorCode;
        end;

        DockAppointment."Dock Door Code" := Chosen;
        DockAppointment.Modify(true);
    end;

    /// <summary>
    /// Checks a vehicle in at the gate and parks it where it was told to wait.
    /// </summary>
    /// <param name="DockAppointment">The booking the vehicle arrived against.</param>
    /// <param name="YardPositionCode">Where the trailer is standing, or blank when it goes straight on.</param>
    procedure Arrive(var DockAppointment: Record "WHA Dock Appointment"; YardPositionCode: Code[20])
    begin
        if DockAppointment.Status <> DockAppointment.Status::WHABooked then
            Error(NotBookedErr, DockAppointment."No.", DockAppointment.Status);

        if (YardPositionCode = '') and PositionRequired() then
            Error(PositionRequiredErr, DockAppointment."No.");

        OccupyPosition(DockAppointment, YardPositionCode);

        DockAppointment.Status := DockAppointment.Status::WHAArrived;
        DockAppointment."Arrived At" := CurrentDateTime;
        DockAppointment.Modify(true);
    end;

    /// <summary>
    /// Brings a waiting vehicle onto its door, and gives the yard position back. The booking keeps a
    /// door it already had; one without a door gets whichever the strategy can find now.
    /// </summary>
    /// <param name="DockAppointment">The booking to bring in.</param>
    /// <returns>The door the vehicle went on.</returns>
    procedure MoveToDoor(var DockAppointment: Record "WHA Dock Appointment"): Code[20]
    var
        DoorCode: Code[20];
    begin
        if DockAppointment.Status <> DockAppointment.Status::WHAArrived then
            Error(NotOnSiteErr, DockAppointment."No.", DockAppointment.Status);

        DoorCode := DockAppointment."Dock Door Code";
        if DoorCode = '' then
            DoorCode := ChooseDoor(DockAppointment);
        if DoorCode = '' then
            Error(NoDoorFreeErr, DockAppointment."Location Code", DockAppointment."No.");

        CheckDoorClearNow(DockAppointment, DoorCode);
        ReleasePosition(DockAppointment);

        DockAppointment."Dock Door Code" := DoorCode;
        DockAppointment.Status := DockAppointment.Status::WHAAtDoor;
        DockAppointment."At Door At" := CurrentDateTime;
        DockAppointment.Modify(true);
        exit(DoorCode);
    end;

    /// <summary>
    /// Sends a vehicle off site, whether it made it to a door or gave up in the yard. The door and the
    /// yard position are freed; the times it was here are kept.
    /// </summary>
    /// <param name="DockAppointment">The booking to close off.</param>
    procedure Depart(var DockAppointment: Record "WHA Dock Appointment")
    begin
        if not (DockAppointment.Status in [DockAppointment.Status::WHAArrived, DockAppointment.Status::WHAAtDoor]) then
            Error(NotHereErr, DockAppointment."No.", DockAppointment.Status);

        ReleasePosition(DockAppointment);

        DockAppointment.Status := DockAppointment.Status::WHADeparted;
        DockAppointment."Departed At" := CurrentDateTime;
        DockAppointment.Modify(true);
    end;

    /// <summary>
    /// Calls a booking off. A vehicle that never came leaves nothing behind but the fact that it was
    /// expected, which is worth keeping.
    /// </summary>
    /// <param name="DockAppointment">The booking to cancel.</param>
    procedure Cancel(var DockAppointment: Record "WHA Dock Appointment")
    begin
        if not (DockAppointment.Status in [DockAppointment.Status::WHABooked, DockAppointment.Status::WHAArrived]) then
            Error(CancelNotAllowedErr, DockAppointment."No.", DockAppointment.Status);

        ReleasePosition(DockAppointment);

        DockAppointment.Status := DockAppointment.Status::WHACancelled;
        DockAppointment.Modify(true);
    end;

    /// <summary>
    /// Answers whether a door could take a booking: the right direction, not blocked, and nothing else
    /// holding an overlapping slot. Door selection strategies ask this rather than deciding for
    /// themselves, so every strategy obeys the same rules.
    /// </summary>
    /// <param name="DockDoor">The door being considered.</param>
    /// <param name="DockAppointment">The booking that needs a door.</param>
    /// <returns>True when the door could take the booking.</returns>
    procedure DoorCanTake(var DockDoor: Record "WHA Dock Door"; var DockAppointment: Record "WHA Dock Appointment"): Boolean
    begin
        if DockDoor.Blocked then
            exit(false);
        if DockDoor."Location Code" <> DockAppointment."Location Code" then
            exit(false);
        if not DirectionFits(DockDoor.Direction, DockAppointment.Direction) then
            exit(false);

        exit(ClashingAppointment(DockAppointment, DockDoor."Code") = '');
    end;

    /// <summary>
    /// Answers whether a booked vehicle is later than the yard is prepared to ignore. Lateness changes
    /// what is highlighted, never what is allowed.
    /// </summary>
    /// <param name="DockAppointment">The booking to test.</param>
    /// <returns>True when the vehicle has not arrived and is past the threshold.</returns>
    procedure IsLate(var DockAppointment: Record "WHA Dock Appointment"): Boolean
    var
        Setup: Record "WHA Dock Setup";
        Grace: Duration;
    begin
        if DockAppointment.Status <> DockAppointment.Status::WHABooked then
            exit(false);
        if DockAppointment."Expected At" = 0DT then
            exit(false);

        Setup.SetLoadFields("Late Threshold Minutes");
        if Setup.Get() then
            Grace := Setup."Late Threshold Minutes" * 60000;

        exit(CurrentDateTime > DockAppointment."Expected At" + Grace);
    end;

    /// <summary>
    /// Answers where a vehicle for this booking would normally wait: the position its door names, when
    /// that position is free to take it. Blank when the booking has no door, the door names no waiting
    /// position, or somebody is already standing in it - in which case whoever checks the vehicle in has
    /// to say where it went.
    /// </summary>
    /// <param name="DockAppointment">The booking whose vehicle is arriving.</param>
    /// <returns>The yard position to park in, or blank when there is nothing to suggest.</returns>
    procedure SuggestedPosition(var DockAppointment: Record "WHA Dock Appointment"): Code[20]
    var
        DockDoor: Record "WHA Dock Door";
        YardPosition: Record "WHA Yard Position";
    begin
        if DockAppointment."Dock Door Code" = '' then
            exit('');

        DockDoor.SetLoadFields("Yard Position Code");
        if not DockDoor.Get(DockAppointment."Location Code", DockAppointment."Dock Door Code") then
            exit('');
        if DockDoor."Yard Position Code" = '' then
            exit('');

        YardPosition.SetLoadFields(Blocked, "Occupied By Appt. No.");
        if not YardPosition.Get(DockAppointment."Location Code", DockDoor."Yard Position Code") then
            exit('');
        if YardPosition.Blocked then
            exit('');
        if (YardPosition."Occupied By Appt. No." <> '') and (YardPosition."Occupied By Appt. No." <> DockAppointment."No.") then
            exit('');

        exit(DockDoor."Yard Position Code");
    end;

    /// <summary>
    /// Describes in one line how the yard chooses a door when nobody names one.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure DescribeSelection(): Text
    var
        DoorSelection: Interface "WHA IDoorSelection";
    begin
        DoorSelection := ConfiguredSelection();
        exit(DoorSelection.Describe());
    end;

    local procedure ChooseDoor(var DockAppointment: Record "WHA Dock Appointment"): Code[20]
    var
        DockDoor: Record "WHA Dock Door";
        DoorSelection: Interface "WHA IDoorSelection";
        Chosen: Code[20];
    begin
        DoorSelection := ConfiguredSelection();
        Chosen := DoorSelection.Choose(DockAppointment);
        if Chosen = '' then
            exit('');

        if not DockDoor.Get(DockAppointment."Location Code", Chosen) then
            exit('');
        if not DoorCanTake(DockDoor, DockAppointment) then
            exit('');

        exit(Chosen);
    end;

    local procedure CheckDoorUsable(var DockAppointment: Record "WHA Dock Appointment"; DoorCode: Code[20])
    var
        DockDoor: Record "WHA Dock Door";
        Clashing: Code[20];
    begin
        if not DockDoor.Get(DockAppointment."Location Code", DoorCode) then
            Error(DoorNotFoundErr, DoorCode, DockAppointment."Location Code");
        if DockDoor.Blocked then
            Error(DoorBlockedErr, DoorCode);
        if not DirectionFits(DockDoor.Direction, DockAppointment.Direction) then
            Error(DoorDirectionErr, DoorCode, DockAppointment.Direction);

        Clashing := ClashingAppointment(DockAppointment, DoorCode);
        if Clashing <> '' then
            Error(DoorTakenErr, DoorCode, Clashing);
    end;

    local procedure CheckDoorClearNow(var DockAppointment: Record "WHA Dock Appointment"; DoorCode: Code[20])
    var
        AtDoor: Record "WHA Dock Appointment";
    begin
        AtDoor.SetCurrentKey("Location Code", "Dock Door Code", Status);
        AtDoor.SetRange("Location Code", DockAppointment."Location Code");
        AtDoor.SetRange("Dock Door Code", DoorCode);
        AtDoor.SetRange(Status, AtDoor.Status::WHAAtDoor);
        AtDoor.SetFilter("No.", '<>%1', DockAppointment."No.");
        if AtDoor.FindFirst() then
            Error(DoorOccupiedErr, AtDoor."No.", DoorCode);
    end;

    local procedure CheckChangeable(var DockAppointment: Record "WHA Dock Appointment")
    begin
        if DockAppointment.Status in [DockAppointment.Status::WHADeparted, DockAppointment.Status::WHACancelled] then
            Error(FinishedErr, DockAppointment."No.", DockAppointment.Status);
    end;

    local procedure ClashingAppointment(var DockAppointment: Record "WHA Dock Appointment"; DoorCode: Code[20]): Code[20]
    var
        Other: Record "WHA Dock Appointment";
        StartsAt: DateTime;
        EndsAt: DateTime;
    begin
        if DoorCode = '' then
            exit('');
        if DockAppointment."Expected At" = 0DT then
            exit('');

        StartsAt := DockAppointment."Expected At";
        EndsAt := SlotEnd(StartsAt, DockAppointment."Slot Minutes");

        Other.SetCurrentKey("Location Code", "Dock Door Code", Status);
        Other.SetRange("Location Code", DockAppointment."Location Code");
        Other.SetRange("Dock Door Code", DoorCode);
        Other.SetFilter(Status, '<>%1&<>%2', Other.Status::WHACancelled, Other.Status::WHADeparted);
        if DockAppointment."No." <> '' then
            Other.SetFilter("No.", '<>%1', DockAppointment."No.");
        if not Other.FindSet() then
            exit('');

        repeat
            if Overlaps(StartsAt, EndsAt, Other."Expected At", SlotEnd(Other."Expected At", Other."Slot Minutes")) then
                exit(Other."No.");
        until Other.Next() = 0;

        exit('');
    end;

    local procedure Overlaps(FirstStart: DateTime; FirstEnd: DateTime; SecondStart: DateTime; SecondEnd: DateTime): Boolean
    begin
        if SecondStart = 0DT then
            exit(false);
        exit((FirstStart < SecondEnd) and (SecondStart < FirstEnd));
    end;

    local procedure SlotEnd(StartsAt: DateTime; SlotMinutes: Integer): DateTime
    var
        SlotLength: Duration;
    begin
        SlotLength := EffectiveSlot(SlotMinutes) * 60000;
        exit(StartsAt + SlotLength);
    end;

    local procedure EffectiveSlot(SlotMinutes: Integer): Integer
    var
        Setup: Record "WHA Dock Setup";
    begin
        if SlotMinutes > 0 then
            exit(SlotMinutes);

        Setup.SetLoadFields("Default Slot Minutes");
        if Setup.Get() then
            if Setup."Default Slot Minutes" > 0 then
                exit(Setup."Default Slot Minutes");

        exit(60);
    end;

    local procedure DirectionFits(DoorDirection: Enum "WHA Door Direction"; ApptDirection: Enum "WHA Dock Direction"): Boolean
    begin
        if DoorDirection = DoorDirection::WHABoth then
            exit(true);
        if ApptDirection = ApptDirection::WHAInbound then
            exit(DoorDirection = DoorDirection::WHAInbound);
        exit(DoorDirection = DoorDirection::WHAOutbound);
    end;

    local procedure OccupyPosition(var DockAppointment: Record "WHA Dock Appointment"; PositionCode: Code[20])
    var
        YardPosition: Record "WHA Yard Position";
    begin
        if PositionCode = '' then
            exit;

        if not YardPosition.Get(DockAppointment."Location Code", PositionCode) then
            Error(PositionNotFoundErr, PositionCode, DockAppointment."Location Code");
        if YardPosition.Blocked then
            Error(PositionBlockedErr, PositionCode);
        if (YardPosition."Occupied By Appt. No." <> '') and (YardPosition."Occupied By Appt. No." <> DockAppointment."No.") then
            Error(PositionTakenErr, PositionCode, YardPosition."Occupied By Appt. No.");

        YardPosition."Occupied By Appt. No." := DockAppointment."No.";
        YardPosition.Modify(true);

        DockAppointment."Yard Position Code" := PositionCode;
    end;

    local procedure ReleasePosition(var DockAppointment: Record "WHA Dock Appointment")
    var
        YardPosition: Record "WHA Yard Position";
    begin
        if DockAppointment."Yard Position Code" = '' then
            exit;

        if YardPosition.Get(DockAppointment."Location Code", DockAppointment."Yard Position Code") then
            if YardPosition."Occupied By Appt. No." = DockAppointment."No." then begin
                YardPosition."Occupied By Appt. No." := '';
                YardPosition.Modify(true);
            end;

        DockAppointment."Yard Position Code" := '';
    end;

    local procedure PositionRequired(): Boolean
    var
        Setup: Record "WHA Dock Setup";
    begin
        Setup.SetLoadFields("Require Yard Position");
        if not Setup.Get() then
            exit(false);
        exit(Setup."Require Yard Position");
    end;

    local procedure ConfiguredSelection(): Enum "WHA Door Selection"
    var
        Setup: Record "WHA Dock Setup";
        Selection: Enum "WHA Door Selection";
    begin
        Setup.SetLoadFields("Door Selection");
        if not Setup.Get() then
            exit(Selection::WHAFirstFree);
        exit(Setup."Door Selection");
    end;
}
