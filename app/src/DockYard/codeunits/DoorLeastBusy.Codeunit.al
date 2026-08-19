namespace WarehouseAdvanced.DockYard;

codeunit 50456 "WHA Door Least Busy" implements "WHA IDoorSelection"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The door with the fewest bookings that day. Spreads the traffic across the building instead of stacking it at one end, at the cost of sending a driver somewhere different each visit.';

    /// <summary>
    /// Chooses the door with the fewest bookings on the day of the appointment. Right for a yard where
    /// the doors are equivalent and the constraint is the people working them, wrong for one where the
    /// far door is a hundred metres from everything else.
    /// </summary>
    /// <param name="DockAppointment">The booking that needs a door.</param>
    /// <returns>The code of the chosen door, or blank when no door will do.</returns>
    procedure Choose(var DockAppointment: Record "WHA Dock Appointment"): Code[20]
    var
        DockDoor: Record "WHA Dock Door";
        DockMgt: Codeunit "WHA Dock Mgt.";
        ChosenCode: Code[20];
        Fewest: Integer;
        Booked: Integer;
    begin
        ChosenCode := '';
        Fewest := 0;

        DockDoor.SetRange("Location Code", DockAppointment."Location Code");
        DockDoor.SetRange(Blocked, false);
        if not DockDoor.FindSet() then
            exit('');

        repeat
            if DockMgt.DoorCanTake(DockDoor, DockAppointment) then begin
                Booked := BookingsOnDay(DockDoor, DockAppointment."Expected At");
                if (ChosenCode = '') or (Booked < Fewest) then begin
                    ChosenCode := DockDoor."Code";
                    Fewest := Booked;
                end;
            end;
        until DockDoor.Next() = 0;

        exit(ChosenCode);
    end;

    /// <summary>
    /// Describes in one line how this strategy picks.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    local procedure BookingsOnDay(var DockDoor: Record "WHA Dock Door"; ExpectedAt: DateTime): Integer
    var
        DockAppointment: Record "WHA Dock Appointment";
        Day: Date;
    begin
        Day := DT2Date(ExpectedAt);
        if Day = 0D then
            Day := WorkDate();

        DockAppointment.SetCurrentKey("Location Code", "Dock Door Code", Status);
        DockAppointment.SetRange("Location Code", DockDoor."Location Code");
        DockAppointment.SetRange("Dock Door Code", DockDoor."Code");
        DockAppointment.SetFilter(Status, '<>%1', DockAppointment.Status::WHACancelled);
        DockAppointment.SetRange("Expected At", CreateDateTime(Day, 0T), CreateDateTime(Day, 235959T));
        exit(DockAppointment.Count());
    end;
}
