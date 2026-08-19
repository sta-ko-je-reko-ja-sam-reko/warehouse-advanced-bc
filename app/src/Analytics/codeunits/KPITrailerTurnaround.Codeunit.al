namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.DockYard;

codeunit 50708 "WHA KPI Trailer Turnaround" implements "WHA IKpiMeasure"
{
    Access = Public;

    var
        DescriptionLbl: Label 'How long a vehicle is on site, from reporting at the gate to leaving it. Hauliers charge for this, so it is usually the first number anybody outside the warehouse asks for.';
        UnitLbl: Label 'minutes';

    /// <summary>
    /// Averages the minutes between a vehicle arriving and leaving, over the appointments that departed
    /// in the period. Vehicles still on site are left out on purpose: a visit that has not finished has
    /// no turnaround, and counting it as one that finished now would flatter every figure taken at noon.
    /// </summary>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count.</param>
    /// <param name="ToDate">The last day to count.</param>
    /// <returns>The average minutes, or zero when nothing left in the period.</returns>
    procedure Calculate(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Decimal
    var
        DockAppointment: Record "WHA Dock Appointment";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        TotalMinutes: Decimal;
        Measured: Integer;
    begin
        DockAppointment.SetCurrentKey(Status, "Location Code");
        DockAppointment.SetRange(Status, DockAppointment.Status::WHADeparted);
        if LocationCode <> '' then
            DockAppointment.SetRange("Location Code", LocationCode);
        DockAppointment.SetRange("Departed At", KpiMgt.DayStart(FromDate), KpiMgt.DayEnd(ToDate));
        if not DockAppointment.FindSet() then
            exit(0);

        repeat
            if DockAppointment."Arrived At" <> 0DT then begin
                TotalMinutes += KpiMgt.MinutesBetween(DockAppointment."Arrived At", DockAppointment."Departed At");
                Measured += 1;
            end;
        until DockAppointment.Next() = 0;

        exit(KpiMgt.Average(TotalMinutes, Measured));
    end;

    /// <summary>
    /// Describes in one line what the number is and what it leaves out.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Names the unit the figure is in.
    /// </summary>
    /// <returns>The unit in the user's language.</returns>
    procedure MeasuredIn(): Text
    begin
        exit(UnitLbl);
    end;

    /// <summary>
    /// Answers which way is good.
    /// </summary>
    /// <returns>False, because a vehicle standing on the yard is costing somebody money.</returns>
    procedure HigherIsBetter(): Boolean
    begin
        exit(false);
    end;
}
