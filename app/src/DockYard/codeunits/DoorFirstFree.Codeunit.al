namespace WarehouseAdvanced.DockYard;

codeunit 50455 "WHA Door First Free" implements "WHA IDoorSelection"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The first free door in code order. Predictable, and it keeps the yard using the same doors first, which is where the people usually are.';

    /// <summary>
    /// Chooses the first door at the location, in code order, that could take the booking. Predictable
    /// beats clever here: a driver who is always sent to the same end of the building learns the way.
    /// </summary>
    /// <param name="DockAppointment">The booking that needs a door.</param>
    /// <returns>The code of the chosen door, or blank when no door will do.</returns>
    procedure Choose(var DockAppointment: Record "WHA Dock Appointment"): Code[20]
    var
        DockDoor: Record "WHA Dock Door";
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        DockDoor.SetRange("Location Code", DockAppointment."Location Code");
        DockDoor.SetRange(Blocked, false);
        if not DockDoor.FindSet() then
            exit('');

        repeat
            if DockMgt.DoorCanTake(DockDoor, DockAppointment) then
                exit(DockDoor."Code");
        until DockDoor.Next() = 0;

        exit('');
    end;

    /// <summary>
    /// Describes in one line how this strategy picks.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
