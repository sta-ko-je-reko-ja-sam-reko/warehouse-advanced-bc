namespace WarehouseAdvanced.Analytics;

codeunit 50700 "WHA KPI Mgt."
{
    Access = Public;

    var
        DateFormulaTok: Label '<-%1D>', Locked = true, Comment = '%1 = the number of days to look back';

    /// <summary>
    /// Works out one measure for one period without keeping it. Reading a figure changes nothing, which
    /// is what makes it safe to put in front of anybody.
    /// </summary>
    /// <param name="KpiMeasure">The measure to work out.</param>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count. Blank uses the period from the setup.</param>
    /// <param name="ToDate">The last day to count. Blank means today.</param>
    /// <returns>The figure for the period.</returns>
    procedure Measure(KpiMeasure: Enum "WHA KPI Measure"; LocationCode: Code[10]; FromDate: Date; ToDate: Date): Decimal
    var
        KpiMeasureImpl: Interface "WHA IKpiMeasure";
    begin
        ResolveDates(FromDate, ToDate);
        KpiMeasureImpl := KpiMeasure;
        exit(KpiMeasureImpl.Calculate(LocationCode, FromDate, ToDate));
    end;

    /// <summary>
    /// Works out every measure for a period and keeps the answers, so that today can be compared with
    /// last month. Capturing the same location, measure and period twice replaces the figure instead of
    /// adding a second one: a period has one answer, and two of them is a question about which is right.
    /// </summary>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count. Blank uses the period from the setup.</param>
    /// <param name="ToDate">The last day to count. Blank means today.</param>
    /// <returns>How many figures were kept.</returns>
    procedure Capture(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Integer
    var
        KpiMeasure: Enum "WHA KPI Measure";
        Ordinal: Integer;
        Kept: Integer;
    begin
        ResolveDates(FromDate, ToDate);

        foreach Ordinal in Enum::"WHA KPI Measure".Ordinals() do begin
            KpiMeasure := Enum::"WHA KPI Measure".FromInteger(Ordinal);
            KeepSnapshot(LocationCode, KpiMeasure, FromDate, ToDate);
            Kept += 1;
        end;

        exit(Kept);
    end;

    /// <summary>
    /// Fills a buffer with every measure for a period, without keeping anything. This is what the
    /// warehouse KPI screen shows: figures worked out on the spot, so nobody is reading last week's
    /// answer without knowing it.
    /// </summary>
    /// <param name="TempKpiSnapshot">The temporary buffer to fill. Existing rows are discarded.</param>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count. Blank is replaced with the resolved date.</param>
    /// <param name="ToDate">The last day to count. Blank is replaced with the resolved date.</param>
    procedure Refresh(var TempKpiSnapshot: Record "WHA KPI Snapshot" temporary; LocationCode: Code[10]; var FromDate: Date; var ToDate: Date)
    var
        KpiMeasure: Enum "WHA KPI Measure";
        Ordinal: Integer;
        EntryNo: Integer;
    begin
        ResolveDates(FromDate, ToDate);

        TempKpiSnapshot.Reset();
        TempKpiSnapshot.DeleteAll();

        foreach Ordinal in Enum::"WHA KPI Measure".Ordinals() do begin
            KpiMeasure := Enum::"WHA KPI Measure".FromInteger(Ordinal);
            EntryNo += 1;

            TempKpiSnapshot.Init();
            TempKpiSnapshot."Entry No." := EntryNo;
            TempKpiSnapshot."Location Code" := LocationCode;
            TempKpiSnapshot.Measure := KpiMeasure;
            TempKpiSnapshot."From Date" := FromDate;
            TempKpiSnapshot."To Date" := ToDate;
            TempKpiSnapshot.Value := Measure(KpiMeasure, LocationCode, FromDate, ToDate);
            TempKpiSnapshot."Measured In" := CopyStr(MeasuredIn(KpiMeasure), 1, MaxStrLen(TempKpiSnapshot."Measured In"));
            TempKpiSnapshot."Captured At" := CurrentDateTime;
            TempKpiSnapshot.Insert(false);
        end;

        if TempKpiSnapshot.FindFirst() then;
    end;

    /// <summary>
    /// Describes in one line what a measure counts and what it leaves out.
    /// </summary>
    /// <param name="KpiMeasure">The measure to describe.</param>
    /// <returns>A short description in the user's language.</returns>
    procedure DescribeMeasure(KpiMeasure: Enum "WHA KPI Measure"): Text
    var
        KpiMeasureImpl: Interface "WHA IKpiMeasure";
    begin
        KpiMeasureImpl := KpiMeasure;
        exit(KpiMeasureImpl.Describe());
    end;

    /// <summary>
    /// Names the unit a measure is in.
    /// </summary>
    /// <param name="KpiMeasure">The measure to ask.</param>
    /// <returns>The unit in the user's language.</returns>
    procedure MeasuredIn(KpiMeasure: Enum "WHA KPI Measure"): Text
    var
        KpiMeasureImpl: Interface "WHA IKpiMeasure";
    begin
        KpiMeasureImpl := KpiMeasure;
        exit(KpiMeasureImpl.MeasuredIn());
    end;

    /// <summary>
    /// Answers which way is good for a measure.
    /// </summary>
    /// <param name="KpiMeasure">The measure to ask.</param>
    /// <returns>True when more is better.</returns>
    procedure HigherIsBetter(KpiMeasure: Enum "WHA KPI Measure"): Boolean
    var
        KpiMeasureImpl: Interface "WHA IKpiMeasure";
    begin
        KpiMeasureImpl := KpiMeasure;
        exit(KpiMeasureImpl.HigherIsBetter());
    end;

    /// <summary>
    /// Compares a kept figure with the last one taken for the same measure and site before it. The app
    /// has no targets, so it will not say a figure is good; the most it will say is which way it moved
    /// since last time, and even that means nothing unless the two periods are the same length.
    /// </summary>
    /// <param name="KpiSnapshot">The figure to compare.</param>
    /// <returns>1 when it moved the right way, -1 when it moved the wrong way, 0 when it did not move or there is nothing to compare with.</returns>
    procedure ComparedWithPrevious(var KpiSnapshot: Record "WHA KPI Snapshot"): Integer
    var
        Previous: Record "WHA KPI Snapshot";
    begin
        Previous.SetCurrentKey("Location Code", Measure, "To Date");
        Previous.SetRange("Location Code", KpiSnapshot."Location Code");
        Previous.SetRange(Measure, KpiSnapshot.Measure);
        Previous.SetFilter("To Date", '<%1', KpiSnapshot."To Date");
        if not Previous.FindLast() then
            exit(0);

        if KpiSnapshot.Value = Previous.Value then
            exit(0);

        if KpiSnapshot.Value > Previous.Value then
            exit(Direction(HigherIsBetter(KpiSnapshot.Measure)));

        exit(Direction(not HigherIsBetter(KpiSnapshot.Measure)));
    end;

    /// <summary>
    /// Fills in the dates a caller left blank, from the period in the setup.
    /// </summary>
    /// <param name="FromDate">The first day to count. Blank is replaced.</param>
    /// <param name="ToDate">The last day to count. Blank is replaced with today.</param>
    procedure ResolveDates(var FromDate: Date; var ToDate: Date)
    var
        Setup: Record "WHA Analytics Setup";
        Days: Integer;
    begin
        if ToDate = 0D then
            ToDate := WorkDate();
        if FromDate <> 0D then
            exit;

        Days := 7;
        Setup.SetLoadFields("Default Period Days");
        if Setup.Get() then
            if Setup."Default Period Days" > 0 then
                Days := Setup."Default Period Days";

        FromDate := CalcDate(StrSubstNo(DateFormulaTok, Days), ToDate);
    end;

    /// <summary>
    /// The first instant of a day, for filtering a date-time column by a date. Shared by the measures so
    /// that they all agree on where a day starts.
    /// </summary>
    /// <param name="Day">The day. Blank means no lower bound.</param>
    /// <returns>The first instant of the day.</returns>
    procedure DayStart(Day: Date): DateTime
    begin
        if Day = 0D then
            exit(0DT);
        exit(CreateDateTime(Day, 0T));
    end;

    /// <summary>
    /// The last instant of a day, for filtering a date-time column by a date. A day ends a millisecond
    /// before the next one starts, which is what stops work finished at five to midnight falling out of
    /// every period.
    /// </summary>
    /// <param name="Day">The day. Blank means no upper bound.</param>
    /// <returns>The last instant of the day.</returns>
    procedure DayEnd(Day: Date): DateTime
    var
        OneMillisecond: Duration;
    begin
        if Day = 0D then
            exit(CreateDateTime(DMY2Date(31, 12, 9999), 0T));

        OneMillisecond := 1;
        exit(CreateDateTime(Day + 1, 0T) - OneMillisecond);
    end;

    /// <summary>
    /// The hours between two moments, as a decimal.
    /// </summary>
    /// <param name="FromDateTime">The earlier moment.</param>
    /// <param name="ToDateTime">The later moment.</param>
    /// <returns>The elapsed hours, or zero when either moment is missing.</returns>
    procedure HoursBetween(FromDateTime: DateTime; ToDateTime: DateTime): Decimal
    begin
        exit(ElapsedMilliseconds(FromDateTime, ToDateTime) / 3600000);
    end;

    /// <summary>
    /// The minutes between two moments, as a decimal.
    /// </summary>
    /// <param name="FromDateTime">The earlier moment.</param>
    /// <param name="ToDateTime">The later moment.</param>
    /// <returns>The elapsed minutes, or zero when either moment is missing.</returns>
    procedure MinutesBetween(FromDateTime: DateTime; ToDateTime: DateTime): Decimal
    begin
        exit(ElapsedMilliseconds(FromDateTime, ToDateTime) / 60000);
    end;

    /// <summary>
    /// An average that answers zero rather than failing when there was nothing to average.
    /// </summary>
    /// <param name="Total">The total.</param>
    /// <param name="Counted">How many things went into it.</param>
    /// <returns>The average, rounded to two places.</returns>
    procedure Average(Total: Decimal; Counted: Integer): Decimal
    begin
        if Counted = 0 then
            exit(0);
        exit(Round(Total / Counted, 0.01));
    end;

    /// <summary>
    /// A percentage that answers zero rather than failing when there was nothing to divide by.
    /// </summary>
    /// <param name="Part">The part.</param>
    /// <param name="Whole">The whole.</param>
    /// <returns>The percentage, rounded to two places.</returns>
    procedure Percentage(Part: Integer; Whole: Integer): Decimal
    begin
        if Whole = 0 then
            exit(0);
        exit(Round(Part / Whole * 100, 0.01));
    end;

    local procedure Direction(Better: Boolean): Integer
    begin
        if Better then
            exit(1);
        exit(-1);
    end;

    local procedure ElapsedMilliseconds(FromDateTime: DateTime; ToDateTime: DateTime): Decimal
    var
        Elapsed: Duration;
        Milliseconds: Decimal;
    begin
        if (FromDateTime = 0DT) or (ToDateTime = 0DT) then
            exit(0);
        if ToDateTime < FromDateTime then
            exit(0);

        Elapsed := ToDateTime - FromDateTime;
        Milliseconds := Elapsed;
        exit(Milliseconds);
    end;

    local procedure KeepSnapshot(LocationCode: Code[10]; KpiMeasure: Enum "WHA KPI Measure"; FromDate: Date; ToDate: Date)
    var
        KpiSnapshot: Record "WHA KPI Snapshot";
        Value: Decimal;
    begin
        Value := Measure(KpiMeasure, LocationCode, FromDate, ToDate);

        KpiSnapshot.SetCurrentKey("Location Code", Measure, "To Date");
        KpiSnapshot.SetRange("Location Code", LocationCode);
        KpiSnapshot.SetRange(Measure, KpiMeasure);
        KpiSnapshot.SetRange("From Date", FromDate);
        KpiSnapshot.SetRange("To Date", ToDate);
        if KpiSnapshot.FindFirst() then begin
            KpiSnapshot.Value := Value;
            KpiSnapshot."Measured In" := CopyStr(MeasuredIn(KpiMeasure), 1, MaxStrLen(KpiSnapshot."Measured In"));
            KpiSnapshot."Captured At" := CurrentDateTime;
            KpiSnapshot."Captured By User ID" := CopyStr(UserId(), 1, MaxStrLen(KpiSnapshot."Captured By User ID"));
            KpiSnapshot.Modify(true);
            exit;
        end;

        KpiSnapshot.Reset();
        KpiSnapshot.Init();
        KpiSnapshot."Location Code" := LocationCode;
        KpiSnapshot.Measure := KpiMeasure;
        KpiSnapshot."From Date" := FromDate;
        KpiSnapshot."To Date" := ToDate;
        KpiSnapshot.Value := Value;
        KpiSnapshot."Measured In" := CopyStr(MeasuredIn(KpiMeasure), 1, MaxStrLen(KpiSnapshot."Measured In"));
        KpiSnapshot.Insert(true);
    end;
}
