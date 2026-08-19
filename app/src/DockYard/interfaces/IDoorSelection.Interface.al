namespace WarehouseAdvanced.DockYard;

interface "WHA IDoorSelection"
{
    /// <summary>
    /// Answers which door a booking should be given when nobody named one. An implementation looks only
    /// at the doors of the booking's own location and may use any rule it likes; whatever it hands back
    /// is checked before it is used - the right direction, not blocked, and free for the slot - so a
    /// strategy cannot put a vehicle on a door the yard would refuse.
    /// </summary>
    /// <param name="DockAppointment">The booking that needs a door.</param>
    /// <returns>The code of the chosen door, or blank when no door will do.</returns>
    procedure Choose(var DockAppointment: Record "WHA Dock Appointment"): Code[20];

    /// <summary>
    /// Describes in one line how this strategy picks, because the two answers differ on a busy morning
    /// and the difference decides how the day is spread across the doors.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
