namespace WarehouseAdvanced.Analytics;

enum 50700 "WHA KPI Measure" implements "WHA IKpiMeasure"
{
    Caption = 'KPI measure';
    Extensible = true;
    DefaultImplementation = "WHA IKpiMeasure" = "WHA KPI Tasks Completed";

    value(0; WHATasksCompleted)
    {
        Caption = 'Jobs finished';
        Implementation = "WHA IKpiMeasure" = "WHA KPI Tasks Completed";
    }
    value(1; WHAPutAwayLeadTime)
    {
        Caption = 'Hours from raised to put away';
        Implementation = "WHA IKpiMeasure" = "WHA KPI Put-away Lead";
    }
    value(2; WHAPickShortRate)
    {
        Caption = 'Picks that came up short';
        Implementation = "WHA IKpiMeasure" = "WHA KPI Pick Short Rate";
    }
    value(3; WHATrailerTurnaround)
    {
        Caption = 'Minutes a vehicle is on site';
        Implementation = "WHA IKpiMeasure" = "WHA KPI Trailer Turnaround";
    }
    value(4; WHADoorWait)
    {
        Caption = 'Minutes waiting for a door';
        Implementation = "WHA IKpiMeasure" = "WHA KPI Door Wait";
    }
}
