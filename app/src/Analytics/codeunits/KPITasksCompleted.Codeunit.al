namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.DirectedWork;

codeunit 50705 "WHA KPI Tasks Completed" implements "WHA IKpiMeasure"
{
    Access = Public;

    var
        DescriptionLbl: Label 'How many warehouse jobs were finished in the period. It counts jobs, not lines and not units, so a job that moved one carton weighs the same as one that moved a pallet.';
        UnitLbl: Label 'jobs';

    /// <summary>
    /// Counts the jobs finished in the period. The plainest measure in the app and the one everything
    /// else is read against: a lead time that improves while this collapses is not an improvement.
    /// </summary>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count.</param>
    /// <param name="ToDate">The last day to count.</param>
    /// <returns>How many jobs were completed.</returns>
    procedure Calculate(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Decimal
    var
        WarehouseTask: Record "WHA Warehouse Task";
        KpiMgt: Codeunit "WHA KPI Mgt.";
        Finished: Integer;
    begin
        WarehouseTask.SetCurrentKey(Status, "Location Code");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHACompleted);
        if LocationCode <> '' then
            WarehouseTask.SetRange("Location Code", LocationCode);
        WarehouseTask.SetRange("Completed At", KpiMgt.DayStart(FromDate), KpiMgt.DayEnd(ToDate));

        Finished := WarehouseTask.Count();
        exit(Finished);
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
    /// <returns>True, because finishing more work is better.</returns>
    procedure HigherIsBetter(): Boolean
    begin
        exit(true);
    end;
}
