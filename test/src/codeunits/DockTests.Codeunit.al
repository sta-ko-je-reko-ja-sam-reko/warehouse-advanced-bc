codeunit 59012 "WHA Dock Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHADOCK', Locked = true;
        InDoorTok: Label 'IN-1', Locked = true;
        OutDoorTok: Label 'OUT-1', Locked = true;
        BothDoorTok: Label 'FLEX-1', Locked = true;
        FirstYardTok: Label 'Y-01', Locked = true;
        SecondYardTok: Label 'Y-02', Locked = true;

    [Test]
    procedure ADoorIsChosenWhenNobodyNamesOne()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] Somebody phoning to book a delivery does not know the doors. The yard does, so the
        // app answers the question rather than asking it.
        ConfigureDock(false);

        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), ''));

        Assert.AreNotEqual('', DockAppointment."Dock Door Code", 'A booking with no door named should be given one.');
        Assert.AreEqual(DockAppointment.Status::WHABooked, DockAppointment.Status, 'A new booking is booked and nothing more.');
    end;

    [Test]
    procedure ADoorOnlyTakesTheDirectionItIsFor()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] Sending a delivery to the despatch door is the sort of mistake that is only found
        // when the lorry is already reversed onto it.
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 100000T), ''));

        asserterror DockMgt.AssignDoor(DockAppointment, CopyStr(OutDoorTok, 1, 20));

        Assert.ExpectedError('does not take');
    end;

    [Test]
    procedure ABlockedDoorTakesNothing()
    var
        DockDoor: Record "WHA Dock Door";
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] A door is blocked because something is wrong with it. Booking onto it anyway sends a
        // vehicle to a door nobody can open. With every inbound door blocked the booking is still taken,
        // without a door, because a promise the yard has already given has to be recorded somewhere.
        ConfigureDock(false);
        BlockDoor(CopyStr(InDoorTok, 1, 20));
        BlockDoor(CopyStr(BothDoorTok, 1, 20));

        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 110000T), ''));

        Assert.AreEqual('', DockAppointment."Dock Door Code", 'No blocked door should have been chosen.');
        DockDoor.Get(CopyStr(LocationTok, 1, 10), CopyStr(InDoorTok, 1, 20));
        Assert.IsTrue(DockDoor.Blocked, 'Booking around a blocked door should leave it blocked.');
        asserterror DockMgt.AssignDoor(DockAppointment, CopyStr(InDoorTok, 1, 20));
        Assert.ExpectedError('blocked');
    end;

    [Test]
    procedure TwoBookingsCannotShareADoorAtTheSameTime()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] This is what a booking system is for. Two lorries promised the same door at the same
        // time is the failure the yard notices at eight in the morning.
        ConfigureDock(false);
        DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InDoorTok, 1, 20));

        DockAppointment.Init();
        DockAppointment."Location Code" := CopyStr(LocationTok, 1, 10);
        DockAppointment.Direction := Direction::WHAInbound;
        DockAppointment."Expected At" := CreateDateTime(WorkDate(), 093000T);
        DockAppointment.Insert(true);

        asserterror DockMgt.AssignDoor(DockAppointment, CopyStr(InDoorTok, 1, 20));

        Assert.ExpectedError('already booked');
    end;

    [Test]
    procedure ABookingAfterTheSlotHasFinishedIsFine()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] A door that refused everything for the rest of the day would be worse than no
        // booking system at all. The slot is an hour, so the next hour is free.
        ConfigureDock(false);
        DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InDoorTok, 1, 20));

        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 103000T), CopyStr(InDoorTok, 1, 20)));

        Assert.AreEqual(CopyStr(InDoorTok, 1, 20), DockAppointment."Dock Door Code", 'A later slot on the same door should be allowed.');
    end;

    [Test]
    procedure CheckingInParksTheTrailerWhereSomebodyCanFindIt()
    var
        DockAppointment: Record "WHA Dock Appointment";
        YardPosition: Record "WHA Yard Position";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] A trailer standing somewhere in a yard nobody wrote down is a trailer somebody walks
        // around looking for.
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InDoorTok, 1, 20)));

        DockMgt.Arrive(DockAppointment, CopyStr(FirstYardTok, 1, 20));

        Assert.AreEqual(DockAppointment.Status::WHAArrived, DockAppointment.Status, 'The vehicle is on site.');
        Assert.AreNotEqual(0DT, DockAppointment."Arrived At", 'Arriving is stamped, because everything else is measured from it.');
        YardPosition.Get(CopyStr(LocationTok, 1, 10), CopyStr(FirstYardTok, 1, 20));
        Assert.AreEqual(DockAppointment."No.", YardPosition."Occupied By Appt. No.", 'The yard position should say what is standing in it.');
    end;

    [Test]
    procedure AYardPositionHoldsOneTrailer()
    var
        FirstAppointment: Record "WHA Dock Appointment";
        SecondAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] Two trailers cannot occupy one square of tarmac, and a yard map that says they can
        // is a yard map nobody trusts.
        ConfigureDock(false);
        FirstAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InDoorTok, 1, 20)));
        SecondAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAOutbound, CreateDateTime(WorkDate(), 090000T), CopyStr(OutDoorTok, 1, 20)));
        DockMgt.Arrive(FirstAppointment, CopyStr(FirstYardTok, 1, 20));

        asserterror DockMgt.Arrive(SecondAppointment, CopyStr(FirstYardTok, 1, 20));

        Assert.ExpectedError('already has');
    end;

    [Test]
    procedure GoingToTheDoorGivesTheYardPositionBack()
    var
        DockAppointment: Record "WHA Dock Appointment";
        YardPosition: Record "WHA Yard Position";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] The yard map has to say where trailers are now, not where they were. A position that
        // is never given back fills the yard up on paper while it empties in fact.
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InDoorTok, 1, 20)));
        DockMgt.Arrive(DockAppointment, CopyStr(FirstYardTok, 1, 20));

        DockMgt.MoveToDoor(DockAppointment);

        Assert.AreEqual(DockAppointment.Status::WHAAtDoor, DockAppointment.Status, 'The vehicle is on the door.');
        Assert.AreEqual('', DockAppointment."Yard Position Code", 'It is not in the yard any more.');
        YardPosition.Get(CopyStr(LocationTok, 1, 10), CopyStr(FirstYardTok, 1, 20));
        Assert.AreEqual('', YardPosition."Occupied By Appt. No.", 'The position is free again.');
    end;

    [Test]
    procedure TwoVehiclesCannotStandAtOneDoor()
    var
        FirstAppointment: Record "WHA Dock Appointment";
        SecondAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] Slots stop the clash being planned; this stops it happening anyway when the first
        // vehicle overruns.
        ConfigureDock(false);
        FirstAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InDoorTok, 1, 20)));
        SecondAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 110000T), CopyStr(InDoorTok, 1, 20)));
        DockMgt.Arrive(FirstAppointment, CopyStr(FirstYardTok, 1, 20));
        DockMgt.MoveToDoor(FirstAppointment);
        DockMgt.Arrive(SecondAppointment, CopyStr(SecondYardTok, 1, 20));

        asserterror DockMgt.MoveToDoor(SecondAppointment);

        Assert.ExpectedError('right now');
    end;

    [Test]
    procedure DepartingFreesTheYardAndKeepsTheTimes()
    var
        DockAppointment: Record "WHA Dock Appointment";
        YardPosition: Record "WHA Yard Position";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] A visit that has finished is the only one with a turnaround, and the times it leaves
        // behind are what the analytics feature reads.
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAOutbound, CreateDateTime(WorkDate(), 140000T), CopyStr(OutDoorTok, 1, 20)));
        DockMgt.Arrive(DockAppointment, CopyStr(SecondYardTok, 1, 20));
        DockMgt.MoveToDoor(DockAppointment);

        DockMgt.Depart(DockAppointment);

        Assert.AreEqual(DockAppointment.Status::WHADeparted, DockAppointment.Status, 'The vehicle has gone.');
        Assert.AreNotEqual(0DT, DockAppointment."Departed At", 'Leaving is stamped.');
        Assert.AreNotEqual(0DT, DockAppointment."At Door At", 'Getting to the door stays stamped.');
        YardPosition.Get(CopyStr(LocationTok, 1, 10), CopyStr(SecondYardTok, 1, 20));
        Assert.AreEqual('', YardPosition."Occupied By Appt. No.", 'Nothing is standing in the yard afterwards.');
    end;

    [Test]
    procedure AVisitThatHappenedCannotBeMadeToDisappear()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] When a vehicle has been on site, when it came and when it left is the only record of
        // what the yard did that day - and the only thing a haulier's invoice can be checked against.
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InDoorTok, 1, 20)));
        DockMgt.Arrive(DockAppointment, CopyStr(FirstYardTok, 1, 20));

        asserterror DockAppointment.Delete(true);

        Assert.ExpectedError('cannot be deleted');
    end;

    [Test]
    procedure ABookingNobodyKeptCanBeCalledOff()
    var
        DockAppointment: Record "WHA Dock Appointment";
        YardPosition: Record "WHA Yard Position";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] Deliveries are cancelled all the time. What matters is that the door and the yard
        // position go back into the pool, and that the fact a vehicle was expected is kept.
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(InDoorTok, 1, 20)));
        DockMgt.Arrive(DockAppointment, CopyStr(FirstYardTok, 1, 20));

        DockMgt.Cancel(DockAppointment);

        Assert.AreEqual(DockAppointment.Status::WHACancelled, DockAppointment.Status, 'The booking is called off.');
        YardPosition.Get(CopyStr(LocationTok, 1, 10), CopyStr(FirstYardTok, 1, 20));
        Assert.AreEqual('', YardPosition."Occupied By Appt. No.", 'The yard position is free again.');
        asserterror DockMgt.Depart(DockAppointment);
        Assert.ExpectedError('cannot leave');
    end;

    [Test]
    procedure AWaitingVehicleNeedsSomewhereToWaitWhenTheYardSaysSo()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] A big yard cannot be run on "it is out there somewhere", and a small one should not
        // be made to type a position it does not have. The setup decides which sort of yard this is.
        ConfigureDock(true);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 090000T), CopyStr(BothDoorTok, 1, 20)));

        asserterror DockMgt.Arrive(DockAppointment, '');

        Assert.ExpectedError('yard position');
    end;

    [Test]
    procedure TheLeastBusyStrategySpreadsTheTraffic()
    var
        Setup: Record "WHA Dock Setup";
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
        Selection: Enum "WHA Door Selection";
    begin
        // [SCENARIO] The two strategies give different answers on a busy morning, which is the whole
        // reason the choice is a setting rather than a decision somebody made once in code.
        ConfigureDock(false);
        Setup.Get();
        Setup.Validate("Door Selection", Selection::WHALeastBusy);
        Setup.Modify(true);
        DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 080000T), CopyStr(InDoorTok, 1, 20));
        DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 093000T), CopyStr(InDoorTok, 1, 20));

        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate(), 130000T), ''));

        Assert.AreEqual(CopyStr(BothDoorTok, 1, 20), DockAppointment."Dock Door Code", 'The quiet door should have been chosen over the busy one.');
    end;

    [Test]
    procedure TheFeatureCreatesTheNumberingItNeeds()
    var
        Setup: Record "WHA Dock Setup";
        NoSeries: Record "No. Series";
        DockFeatureSetup: Codeunit "WHA Dock Feature Setup";
    begin
        // [SCENARIO] Numbering belongs to the feature that uses it, not to a shared foundation table. A
        // yard that is never switched on should never have been asked about a series it does not need,
        // and switching it on should not send somebody off to a different page to finish the job.
        DockFeatureSetup.ApplyChoices(true, true, false);

        Setup.Get();
        Assert.AreNotEqual('', Setup."Dock Appointment Nos.", 'Enabling the feature with numbering asked for should fill in its own series.');
        Assert.IsTrue(NoSeries.Get(Setup."Dock Appointment Nos."), 'The series it names should have been created.');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DemoDock: Codeunit "WHA Demo Dock";
        CountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Sample data that piles up every time somebody runs the importer is sample data that
        // has to be cleaned out by hand.
        EnsureAppointmentNoSeries();
        DemoDock.Import();
        CountAfterFirstRun := DockAppointment.Count();

        DemoDock.Import();

        Assert.AreEqual(CountAfterFirstRun, DockAppointment.Count(), 'A second import should not book more vehicles in.');
    end;

    [Test]
    procedure LeastBusyPicksTheQuieterDoorWhereFirstFreeWouldNot()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
        Selection: Enum "WHA Door Selection";
        BookingDay: Date;
    begin
        // [SCENARIO] The door that sorts first is also the one carrying the morning's traffic. First free
        // would take it; least busy must not, or the setting changes nothing.
        // [GIVEN] Least busy, and two bookings on the flexible door, which sorts before the inbound door
        ConfigureDock(false);
        UseSelection(Selection::WHALeastBusy);
        BookingDay := WorkDate() + 30;
        DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(BookingDay, 080000T), CopyStr(BothDoorTok, 1, 20));
        DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(BookingDay, 093000T), CopyStr(BothDoorTok, 1, 20));

        // [WHEN] An afternoon booking names no door
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(BookingDay, 130000T), ''));

        // [THEN] The inbound door, which has nothing booked that day, is chosen
        Assert.AreEqual(CopyStr(InDoorTok, 1, 20), DockAppointment."Dock Door Code", 'Least busy should pick the door with fewer bookings that day.');
        UseSelection(Selection::WHAFirstFree);
    end;

    [Test]
    procedure FirstFreeTakesTheFirstDoorThatCanTakeTheVehicle()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
        Selection: Enum "WHA Door Selection";
        BookingDay: Date;
    begin
        // [GIVEN] First free, and the same two morning bookings on the flexible door
        ConfigureDock(false);
        UseSelection(Selection::WHAFirstFree);
        BookingDay := WorkDate() + 31;
        DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(BookingDay, 080000T), CopyStr(BothDoorTok, 1, 20));
        DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(BookingDay, 093000T), CopyStr(BothDoorTok, 1, 20));

        // [WHEN] An afternoon booking names no door
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(BookingDay, 130000T), ''));

        // [THEN] The flexible door, free in the afternoon and first in order, is chosen
        Assert.AreEqual(CopyStr(BothDoorTok, 1, 20), DockAppointment."Dock Door Code", 'First free should pick the first door that is free at that time.');
    end;

    [Test]
    procedure ABookingMustSayWhereAndWhen()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [GIVEN] The yard set up
        ConfigureDock(false);

        // [WHEN] A booking names no site
        asserterror DockMgt.Book('', Direction::WHAInbound, CreateDateTime(WorkDate(), 100000T), '');
        // [THEN] The site is asked for
        Assert.ExpectedError('Say which site the vehicle is coming to.');

        // [WHEN] A booking names no time
        asserterror DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, 0DT, '');
        // [THEN] The time is asked for
        Assert.ExpectedError('Say when the vehicle is expected.');
    end;

    [Test]
    procedure ADoorThatIsNotThereCannotBeBooked()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [GIVEN] The yard set up
        ConfigureDock(false);

        // [WHEN] A booking names a door the site does not have
        asserterror DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate() + 32, 100000T), 'NO-SUCH-DOOR');

        // [THEN] The door and the site are named
        Assert.ExpectedError('There is no door NO-SUCH-DOOR at WHADOCK.');
    end;

    [Test]
    procedure ADoorOnlyTakesVehiclesGoingItsWay()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [GIVEN] The yard set up with an outbound-only door
        ConfigureDock(false);

        // [WHEN] An inbound vehicle is booked onto it
        asserterror DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate() + 33, 100000T), CopyStr(OutDoorTok, 1, 20));

        // [THEN] It is refused
        Assert.ExpectedError('Door OUT-1 does not take');
    end;

    [Test]
    procedure OnlyABookedVehicleCanArrive()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [GIVEN] A booking that was called off
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate() + 34, 100000T), ''));
        DockMgt.Cancel(DockAppointment);

        // [WHEN] The vehicle is checked in anyway
        asserterror DockMgt.Arrive(DockAppointment, '');

        // [THEN] It is refused
        Assert.ExpectedError('so it cannot be checked in. Only a booked vehicle arrives.');
    end;

    [Test]
    procedure AVehicleCannotBeParkedSomewhereThatIsNotThere()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [GIVEN] A booking
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate() + 35, 100000T), ''));

        // [WHEN] The vehicle is checked in to a yard position the site does not have
        asserterror DockMgt.Arrive(DockAppointment, 'Y-NONE');

        // [THEN] The position is named
        Assert.ExpectedError('There is no yard position Y-NONE at WHADOCK.');
    end;

    [Test]
    procedure AVehicleHasToBeOnSiteBeforeItGoesToADoor()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [GIVEN] A booking for a vehicle that has not arrived
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate() + 36, 100000T), ''));

        // [WHEN] It is put on its door
        asserterror DockMgt.MoveToDoor(DockAppointment);

        // [THEN] It is refused
        Assert.ExpectedError('so it cannot be put on a door. A vehicle has to be on site first.');
    end;

    [Test]
    procedure AVehicleAtTheDoorCannotBeCalledOff()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [SCENARIO] A vehicle standing at the door is being worked. Calling it off would lose the fact
        // that it came; it departs instead.
        // [GIVEN] A vehicle at its door
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAOutbound, CreateDateTime(WorkDate() + 37, 100000T), CopyStr(OutDoorTok, 1, 20)));
        DockMgt.Arrive(DockAppointment, '');
        DockMgt.MoveToDoor(DockAppointment);

        // [WHEN] It is called off
        asserterror DockMgt.Cancel(DockAppointment);

        // [THEN] It is refused
        Assert.ExpectedError('so it cannot be called off');
    end;

    [Test]
    procedure ABookingIsLateOnlyOnceTheGraceHasPassed()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        // [GIVEN] A thirty-minute grace, and a booked vehicle expected two hours ago
        ConfigureDock(false);
        DockAppointment.Init();
        DockAppointment.Status := DockAppointment.Status::WHABooked;
        DockAppointment."Expected At" := CurrentDateTime - 2 * 60 * 60 * 1000;

        // [THEN] It is late
        Assert.IsTrue(DockMgt.IsLate(DockAppointment), 'Two hours past the time is late.');

        // [GIVEN] A booked vehicle expected ten minutes ago
        DockAppointment."Expected At" := CurrentDateTime - 10 * 60 * 1000;
        // [THEN] It is still within the grace
        Assert.IsFalse(DockMgt.IsLate(DockAppointment), 'Ten minutes past the time is within the grace.');

        // [GIVEN] A vehicle expected two hours ago that has already arrived
        DockAppointment.Status := DockAppointment.Status::WHAArrived;
        DockAppointment."Expected At" := CurrentDateTime - 2 * 60 * 60 * 1000;
        // [THEN] It is not late, because it is here
        Assert.IsFalse(DockMgt.IsLate(DockAppointment), 'A vehicle that arrived is not late.');
    end;

    [Test]
    procedure EachStrategyExplainsItself()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
        Selection: Enum "WHA Door Selection";
        FirstFreeText: Text;
    begin
        // [GIVEN] First free
        ConfigureDock(false);
        FirstFreeText := DockMgt.DescribeSelection();

        // [WHEN] The strategy changes to least busy
        UseSelection(Selection::WHALeastBusy);

        // [THEN] Each has its own description
        Assert.AreNotEqual('', FirstFreeText, 'First free should explain itself.');
        Assert.AreNotEqual(FirstFreeText, DockMgt.DescribeSelection(), 'The two strategies should not share a description.');
        UseSelection(Selection::WHAFirstFree);
    end;

    local procedure UseSelection(Selection: Enum "WHA Door Selection")
    var
        Setup: Record "WHA Dock Setup";
    begin
        Setup.Get();
        Setup.Validate("Door Selection", Selection);
        Setup.Modify(true);
    end;

    [Test]
    procedure AVehicleIsNotPutOnADoorBlockedAfterBooking()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
        DoorDirection: Enum "WHA Door Direction";
    begin
        // [SCENARIO] Regression. A booking keeps the door it was given, but the door can be blocked between
        // booking and arrival. Moving the vehicle on used to check only whether another vehicle stood there.
        // [GIVEN] A vehicle booked onto the inbound door, which is blocked after it arrives
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate() + 40, 100000T), CopyStr(InDoorTok, 1, 20)));
        DockMgt.Arrive(DockAppointment, '');
        BlockDoor(CopyStr(InDoorTok, 1, 20));

        // [WHEN] The vehicle is put on its door
        asserterror DockMgt.MoveToDoor(DockAppointment);

        // [THEN] It is refused, because the door is blocked
        Assert.ExpectedError('Door IN-1 is blocked');
        EnsureDoor(CopyStr(InDoorTok, 1, 20), DoorDirection::WHAInbound);
    end;

    [Test]
    procedure AVehicleIsNotPutOnADoorThatNoLongerFacesItsWay()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
        DoorDirection: Enum "WHA Door Direction";
    begin
        // [GIVEN] An inbound vehicle booked onto the flexible door, which is turned outbound-only after it arrives
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate() + 41, 100000T), CopyStr(BothDoorTok, 1, 20)));
        DockMgt.Arrive(DockAppointment, '');
        EnsureDoor(CopyStr(BothDoorTok, 1, 20), DoorDirection::WHAOutbound);

        // [WHEN] The vehicle is put on its door
        asserterror DockMgt.MoveToDoor(DockAppointment);

        // [THEN] It is refused, because the door takes the other direction
        Assert.ExpectedError('Door FLEX-1 does not take');
        EnsureDoor(CopyStr(BothDoorTok, 1, 20), DoorDirection::WHABoth);
    end;

    [Test]
    procedure ABookingFromOutsideIsCheckedLikeAnyOther()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        // [SCENARIO] Regression. The API page inserted what it was sent, so an agent could book a blocked
        // door, a door facing the wrong way or a slot already taken. It now books through the same logic.
        // [GIVEN] An inbound booking filled in by a caller who names the outbound-only door
        ConfigureDock(false);
        DockAppointment.Init();
        DockAppointment."Location Code" := CopyStr(LocationTok, 1, 10);
        DockAppointment.Direction := DockAppointment.Direction::WHAInbound;
        DockAppointment."Expected At" := CreateDateTime(WorkDate() + 42, 100000T);
        DockAppointment."Carrier Name" := 'Outside carrier';

        // [WHEN] It is booked the way the API page books it
        asserterror DockMgt.BookAppointment(DockAppointment, CopyStr(OutDoorTok, 1, 20));

        // [THEN] It is refused
        Assert.ExpectedError('Door OUT-1 does not take');
    end;

    [Test]
    procedure ABookingFromOutsideWithoutADoorGetsOneChosen()
    var
        DockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        // [GIVEN] An outbound booking filled in by a caller who names no door
        ConfigureDock(false);
        DockAppointment.Init();
        DockAppointment."Location Code" := CopyStr(LocationTok, 1, 10);
        DockAppointment.Direction := DockAppointment.Direction::WHAOutbound;
        DockAppointment."Expected At" := CreateDateTime(WorkDate() + 43, 100000T);
        DockAppointment."Carrier Name" := 'Outside carrier';

        // [WHEN] It is booked the way the API page books it
        DockMgt.BookAppointment(DockAppointment, '');

        // [THEN] It is numbered, keeps what the caller sent, and has a door that takes outbound vehicles
        Assert.AreNotEqual('', DockAppointment."No.", 'The booking is numbered.');
        DockAppointment.Get(DockAppointment."No.");
        Assert.AreEqual('Outside carrier', DockAppointment."Carrier Name", 'What the caller sent is kept.');
        Assert.IsTrue(DockAppointment."Dock Door Code" in [CopyStr(OutDoorTok, 1, 20), CopyStr(BothDoorTok, 1, 20)], 'An outbound booking gets a door that takes outbound vehicles.');
    end;

    [Test]
    procedure ChangingABookingFromOutsideRechecksTheDoor()
    var
        DockAppointment: Record "WHA Dock Appointment";
        xDockAppointment: Record "WHA Dock Appointment";
        DockMgt: Codeunit "WHA Dock Mgt.";
        Direction: Enum "WHA Dock Direction";
    begin
        // [GIVEN] An inbound booking on the inbound door
        ConfigureDock(false);
        DockAppointment.Get(DockMgt.Book(CopyStr(LocationTok, 1, 10), Direction::WHAInbound, CreateDateTime(WorkDate() + 44, 100000T), CopyStr(InDoorTok, 1, 20)));

        // [WHEN] A caller changes only who is coming
        xDockAppointment := DockAppointment;
        DockAppointment."Carrier Name" := 'Changed carrier';
        DockMgt.ChangeBooking(DockAppointment, xDockAppointment);
        // [THEN] The change is saved and the door is left alone
        DockAppointment.Get(DockAppointment."No.");
        Assert.AreEqual('Changed carrier', DockAppointment."Carrier Name", 'A change that does not touch the door is saved.');
        Assert.AreEqual(CopyStr(InDoorTok, 1, 20), DockAppointment."Dock Door Code", 'The door is left as it was.');

        // [WHEN] A caller moves it onto the outbound-only door
        xDockAppointment := DockAppointment;
        DockAppointment."Dock Door Code" := CopyStr(OutDoorTok, 1, 20);
        asserterror DockMgt.ChangeBooking(DockAppointment, xDockAppointment);
        // [THEN] It is refused
        Assert.ExpectedError('Door OUT-1 does not take');
    end;

    local procedure ConfigureDock(RequirePosition: Boolean)
    var
        Setup: Record "WHA Dock Setup";
        Selection: Enum "WHA Door Selection";
        DoorDirection: Enum "WHA Door Direction";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        Setup.Validate("Door Selection", Selection::WHAFirstFree);
        Setup.Validate("Default Slot Minutes", 60);
        Setup.Validate("Late Threshold Minutes", 30);
        Setup.Validate("Require Yard Position", RequirePosition);
        Setup.Modify(true);

        EnsureLocation(CopyStr(LocationTok, 1, 10));
        EnsureDoor(CopyStr(InDoorTok, 1, 20), DoorDirection::WHAInbound);
        EnsureDoor(CopyStr(OutDoorTok, 1, 20), DoorDirection::WHAOutbound);
        EnsureDoor(CopyStr(BothDoorTok, 1, 20), DoorDirection::WHABoth);
        EnsurePosition(CopyStr(FirstYardTok, 1, 20));
        EnsurePosition(CopyStr(SecondYardTok, 1, 20));
        EnsureAppointmentNoSeries();
        ClearAppointments();
    end;

    local procedure ClearAppointments()
    var
        DockAppointment: Record "WHA Dock Appointment";
        YardPosition: Record "WHA Yard Position";
    begin
        DockAppointment.SetRange("Location Code", CopyStr(LocationTok, 1, 10));
        DockAppointment.DeleteAll(false);

        YardPosition.SetRange("Location Code", CopyStr(LocationTok, 1, 10));
        YardPosition.ModifyAll("Occupied By Appt. No.", '', false);
    end;

    local procedure EnsureLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            exit;

        Location.Init();
        Location.Code := LocationCode;
        Location.Insert();
    end;

    local procedure EnsureDoor(DoorCode: Code[20]; Direction: Enum "WHA Door Direction")
    var
        DockDoor: Record "WHA Dock Door";
    begin
        if DockDoor.Get(CopyStr(LocationTok, 1, 10), DoorCode) then begin
            DockDoor.Blocked := false;
            DockDoor.Direction := Direction;
            DockDoor.Modify(true);
            exit;
        end;

        DockDoor.Init();
        DockDoor."Location Code" := CopyStr(LocationTok, 1, 10);
        DockDoor."Code" := DoorCode;
        DockDoor.Direction := Direction;
        DockDoor.Insert(true);
    end;

    local procedure BlockDoor(DoorCode: Code[20])
    var
        DockDoor: Record "WHA Dock Door";
    begin
        DockDoor.Get(CopyStr(LocationTok, 1, 10), DoorCode);
        DockDoor.Blocked := true;
        DockDoor.Modify(true);
    end;

    local procedure EnsurePosition(PositionCode: Code[20])
    var
        YardPosition: Record "WHA Yard Position";
    begin
        if YardPosition.Get(CopyStr(LocationTok, 1, 10), PositionCode) then
            exit;

        YardPosition.Init();
        YardPosition."Location Code" := CopyStr(LocationTok, 1, 10);
        YardPosition."Code" := PositionCode;
        YardPosition.Insert(true);
    end;

    local procedure EnsureAppointmentNoSeries()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        Setup: Record "WHA Dock Setup";
    begin
        if not NoSeries.Get('WHA-DTEST') then begin
            NoSeries.Init();
            NoSeries.Code := 'WHA-DTEST';
            NoSeries."Default Nos." := true;
            NoSeries.Insert(true);

            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeries.Code;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'DT000001';
            NoSeriesLine."Ending No." := 'DT999999';
            NoSeriesLine.Insert(true);
        end;

        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        if Setup."Dock Appointment Nos." <> '' then
            exit;

        Setup.Validate("Dock Appointment Nos.", 'WHA-DTEST');
        Setup.Modify(true);
    end;
}
