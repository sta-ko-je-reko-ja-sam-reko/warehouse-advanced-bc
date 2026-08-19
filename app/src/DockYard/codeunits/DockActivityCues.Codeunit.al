namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

codeunit 50457 "WHA Dock Activity Cues" implements "WHA IActivityCues"
{
    Access = Public;

    /// <summary>
    /// Adds this feature's counts to what the role centre is waiting for. A feature that is switched off
    /// adds nothing, so its tiles stay at zero rather than counting work nobody can act on.
    /// </summary>
    /// <param name="Results">The result buffer, keyed by cue field number.</param>
    procedure AddCounts(var Results: Dictionary of [Text, Text])
    var
        ActivitiesCue: Record "WHA Activities Cue";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        if not FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHADockYard) then
            exit;

        Results.Add(Format(ActivitiesCue.FieldNo("WHA Vehicles On Site")), Format(CountVehiclesOnSite()));
        Results.Add(Format(ActivitiesCue.FieldNo("WHA Vehicles Waiting")), Format(CountVehiclesWaitingForADoor()));
    end;


    local procedure CountVehiclesOnSite(): Integer
    var
        DockAppointment: Record "WHA Dock Appointment";
    begin
        DockAppointment.SetFilter(Status, '%1|%2', DockAppointment.Status::WHAArrived, DockAppointment.Status::WHAAtDoor);
        exit(DockAppointment.Count());
    end;
    local procedure CountVehiclesWaitingForADoor(): Integer
    var
        DockAppointment: Record "WHA Dock Appointment";
    begin
        DockAppointment.SetRange(Status, DockAppointment.Status::WHAArrived);
        exit(DockAppointment.Count());
    end;
}
