namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.DirectedWork;

codeunit 50707 "WHA KPI Pick Short Rate" implements "WHA IKpiMeasure"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The share of finished picks that came back with less than they asked for. Every one of them is a customer order somebody has to deal with, and the reason the picker gave is on the job itself.';
        UnitLbl: Label 'percent';

    /// <summary>
    /// Works out what share of the finished picks came up short. This is the measure that turns the
    /// short reason the handheld records into something a manager can act on, because one short pick is
    /// an incident and forty a week is a process.
    /// </summary>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count.</param>
    /// <param name="ToDate">The last day to count.</param>
    /// <returns>The percentage of picks that were short, or zero when nothing was picked.</returns>
    procedure Calculate(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Decimal
    var
        WarehouseTask: Record "WHA Warehouse Task";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        Picks: Integer;
        Short: Integer;
    begin
        WarehouseTask.SetCurrentKey(Status, "Location Code");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHACompleted);
        WarehouseTask.SetRange("Task Type", WarehouseTask."Task Type"::WHAPick);
        if LocationCode <> '' then
            WarehouseTask.SetRange("Location Code", LocationCode);
        WarehouseTask.SetRange("Completed At", KpiMgt.DayStart(FromDate), KpiMgt.DayEnd(ToDate));
        if not WarehouseTask.FindSet() then
            exit(0);

        repeat
            Picks += 1;
            if WarehouseTask."Quantity Handled" < WarehouseTask.Quantity then
                Short += 1;
        until WarehouseTask.Next() = 0;

        exit(KpiMgt.Percentage(Short, Picks));
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
    /// <returns>False, because a short pick is a promise the warehouse could not keep.</returns>
    procedure HigherIsBetter(): Boolean
    begin
        exit(false);
    end;
}
