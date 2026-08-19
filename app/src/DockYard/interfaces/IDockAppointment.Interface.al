namespace WarehouseAdvanced.DockYard;

interface "WHA IDockAppointment"
{
    /// <summary>
    /// Numbers the appointment from the foundation series and applies the defaults a new booking needs.
    /// </summary>
    /// <param name="DockAppointment">The appointment being inserted.</param>
    procedure Trigger_OnInsert(var DockAppointment: Record "WHA Dock Appointment");

    /// <summary>
    /// Refuses to delete an appointment whose lorry has already turned up, and frees whatever a booking
    /// that never arrived was holding. When a vehicle has been on site, the times it was here are the
    /// only record of what the yard did that day.
    /// </summary>
    /// <param name="DockAppointment">The appointment being deleted.</param>
    procedure Trigger_OnDelete(var DockAppointment: Record "WHA Dock Appointment");
}
