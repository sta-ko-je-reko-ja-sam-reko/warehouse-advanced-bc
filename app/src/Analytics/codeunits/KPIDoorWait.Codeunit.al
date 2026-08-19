namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.DockYard;

codeunit 50709 "WHA KPI Door Wait" implements "WHA IKpiMeasure"
{
    Access = Public;

    var
        DescriptionLbl: Label 'How long a vehicle waits between reporting at the gate and being put on a door. This is the part of the turnaround the warehouse controls, and the part a driver complains about.';
        UnitLbl: Label 'minutes';

    /// <summary>
    /// Averages the minutes a vehicle waits before it gets a door, over the appointments that reached one
    /// in the period. Kept apart from the turnaround because the two have different owners: waiting is
    /// the yard, and the time on the door is the warehouse.
    /// </summary>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count.</param>
    /// <param name="ToDate">The last day to count.</param>
    /// <returns>The average minutes, or zero when nothing reached a door in the period.</returns>
    procedure Calculate(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Decimal
    var
        DockAppointment: Record "WHA Dock Appointment";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        TotalMinutes: Decimal;
        Measured: Integer;
    begin
        if LocationCode <> '' then
            DockAppointment.SetRange("Location Code", LocationCode);
        DockAppointment.SetRange("At Door At", KpiMgt.DayStart(FromDate), KpiMgt.DayEnd(ToDate));
        if not DockAppointment.FindSet() then
            exit(0);

        repeat
            if DockAppointment."Arrived At" <> 0DT then begin
                TotalMinutes += KpiMgt.MinutesBetween(DockAppointment."Arrived At", DockAppointment."At Door At");
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
    /// <returns>False, because nothing happens while a vehicle waits.</returns>
    procedure HigherIsBetter(): Boolean
    begin
        exit(false);
    end;
}
