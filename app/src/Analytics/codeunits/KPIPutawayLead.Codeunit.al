namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.DirectedWork;

codeunit 50706 "WHA KPI Put-away Lead" implements "WHA IKpiMeasure"
{
    Access = Public;

    var
        DescriptionLbl: Label 'How long a put-away job waits between being raised and being finished. This is the half of dock-to-stock the app can actually see: it starts when the work was created, not when the lorry arrived, so unloading and paperwork are not in it.';
        UnitLbl: Label 'hours';

    /// <summary>
    /// Averages the hours between a put-away job being raised and being finished. Named carefully: a
    /// warehouse asking for dock-to-stock wants the clock to start at the gate, and nothing in the app
    /// ties a put-away to the vehicle that brought the goods.
    /// </summary>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count.</param>
    /// <param name="ToDate">The last day to count.</param>
    /// <returns>The average hours, or zero when nothing was put away.</returns>
    procedure Calculate(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Decimal
    var
        WarehouseTask: Record "WHA Warehouse Task";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        TotalHours: Decimal;
        Measured: Integer;
    begin
        WarehouseTask.SetCurrentKey(Status, "Location Code");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHACompleted);
        WarehouseTask.SetRange("Task Type", WarehouseTask."Task Type"::WHAPutAway);
        if LocationCode <> '' then
            WarehouseTask.SetRange("Location Code", LocationCode);
        WarehouseTask.SetRange("Completed At", KpiMgt.DayStart(FromDate), KpiMgt.DayEnd(ToDate));
        if not WarehouseTask.FindSet() then
            exit(0);

        repeat
            if WarehouseTask.SystemCreatedAt <> 0DT then begin
                TotalHours += KpiMgt.HoursBetween(WarehouseTask.SystemCreatedAt, WarehouseTask."Completed At");
                Measured += 1;
            end;
        until WarehouseTask.Next() = 0;

        exit(KpiMgt.Average(TotalHours, Measured));
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
    /// <returns>False, because goods sitting on the floor waiting to be put away help nobody.</returns>
    procedure HigherIsBetter(): Boolean
    begin
        exit(false);
    end;
}
