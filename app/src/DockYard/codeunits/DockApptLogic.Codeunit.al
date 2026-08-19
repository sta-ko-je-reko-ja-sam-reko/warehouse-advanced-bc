namespace WarehouseAdvanced.DockYard;

using Microsoft.Foundation.NoSeries;

codeunit 50451 "WHA Dock Appt. Logic" implements "WHA IDockAppointment"
{
    Access = Public;

    var
        NoSeriesMissingErr: Label 'Set the dock appointment number series on the dock and yard setup page before booking anything in.';
        DeleteNotAllowedErr: Label 'Appointment %1 is %2, so it cannot be deleted. Once a vehicle has been on site, when it came and when it left is the only record of what the yard did that day.', Comment = '%1 = the appointment number, %2 = the current status';

    /// <summary>
    /// Numbers the appointment from the foundation series and applies the defaults a new booking needs.
    /// </summary>
    /// <param name="DockAppointment">The appointment being inserted.</param>
    procedure Trigger_OnInsert(var DockAppointment: Record "WHA Dock Appointment")
    var
        Setup: Record "WHA Dock Setup";
    begin
        if DockAppointment."No." = '' then
            DockAppointment."No." := NextAppointmentNo();

        DockAppointment."Created At" := CurrentDateTime;
        DockAppointment."Booked By User ID" := CopyStr(UserId(), 1, MaxStrLen(DockAppointment."Booked By User ID"));

        if DockAppointment."Slot Minutes" <> 0 then
            exit;

        Setup.SetLoadFields("Default Slot Minutes");
        if not Setup.Get() then
            exit;
        DockAppointment."Slot Minutes" := Setup."Default Slot Minutes";
    end;

    /// <summary>
    /// Refuses to delete an appointment whose vehicle has already turned up, and frees whatever a booking
    /// that never arrived was holding.
    /// </summary>
    /// <param name="DockAppointment">The appointment being deleted.</param>
    procedure Trigger_OnDelete(var DockAppointment: Record "WHA Dock Appointment")
    var
        YardPosition: Record "WHA Yard Position";
    begin
        if DockAppointment.Status in [DockAppointment.Status::WHAArrived, DockAppointment.Status::WHAAtDoor, DockAppointment.Status::WHADeparted] then
            Error(DeleteNotAllowedErr, DockAppointment."No.", DockAppointment.Status);

        if DockAppointment."Yard Position Code" = '' then
            exit;

        if not YardPosition.Get(DockAppointment."Location Code", DockAppointment."Yard Position Code") then
            exit;
        if YardPosition."Occupied By Appt. No." <> DockAppointment."No." then
            exit;

        YardPosition."Occupied By Appt. No." := '';
        YardPosition.Modify(true);
    end;

    local procedure NextAppointmentNo(): Code[20]
    var
        Setup: Record "WHA Dock Setup";
        NoSeries: Codeunit "No. Series";
    begin
        Setup.SetLoadFields("Dock Appointment Nos.");
        if not Setup.Get() then
            Error(NoSeriesMissingErr);
        if Setup."Dock Appointment Nos." = '' then
            Error(NoSeriesMissingErr);

        exit(NoSeries.GetNextNo(Setup."Dock Appointment Nos."));
    end;
}
