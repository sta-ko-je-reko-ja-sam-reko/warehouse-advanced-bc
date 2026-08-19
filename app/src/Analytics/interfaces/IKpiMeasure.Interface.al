namespace WarehouseAdvanced.Analytics;

interface "WHA IKpiMeasure"
{
    /// <summary>
    /// Answers one number about one period. A measure reads what the app has already recorded and works
    /// out nothing else: it never writes, and it never asks another measure for anything, so measures can
    /// be added and removed without disturbing each other.
    /// </summary>
    /// <param name="LocationCode">The site to measure, or blank for the whole company.</param>
    /// <param name="FromDate">The first day to count.</param>
    /// <param name="ToDate">The last day to count.</param>
    /// <returns>The figure for the period. Zero when there is nothing to measure, which is not the same as a bad result.</returns>
    procedure Calculate(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Decimal;

    /// <summary>
    /// Describes in one line what the number is and what it deliberately leaves out, because a KPI nobody
    /// can define is a KPI everybody argues about.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;

    /// <summary>
    /// Names the unit the figure is in, so a number is never shown without one.
    /// </summary>
    /// <returns>The unit in the user's language.</returns>
    procedure MeasuredIn(): Text;

    /// <summary>
    /// Answers which way is good. The app never judges a figure against a target - it has none - but it
    /// has to know which direction to colour.
    /// </summary>
    /// <returns>True when more is better.</returns>
    procedure HigherIsBetter(): Boolean;
}
