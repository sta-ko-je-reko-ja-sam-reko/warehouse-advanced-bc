namespace WarehouseAdvanced.Counting;

interface "WHA ICountSheetLine"
{
    /// <summary>
    /// Gives a new line its position on the sheet.
    /// </summary>
    /// <param name="CountSheetLine">The line being inserted.</param>
    procedure Trigger_OnInsert(var CountSheetLine: Record "WHA Count Sheet Line");

    /// <summary>
    /// Refuses to delete a line off a sheet that has left the desk, so nobody can make a difference
    /// disappear by removing the line that showed it.
    /// </summary>
    /// <param name="CountSheetLine">The line being deleted.</param>
    procedure Trigger_OnDelete(var CountSheetLine: Record "WHA Count Sheet Line");

    /// <summary>
    /// Works out the difference from what was expected and decides whether it is bigger than the tolerance
    /// allows. Counting a line again replaces the number and withdraws any approval, because an approved
    /// difference is an approval of a number, not of a line.
    /// </summary>
    /// <param name="CountSheetLine">The line being counted.</param>
    /// <param name="xCountSheetLine">The line as it was before the count was entered.</param>
    procedure Validate_CountedQuantity(var CountSheetLine: Record "WHA Count Sheet Line"; xCountSheetLine: Record "WHA Count Sheet Line");

    /// <summary>
    /// Records what was actually found. The programmatic way in: it validates the counted quantity and
    /// saves the line, so callers do not have to remember both.
    /// </summary>
    /// <param name="CountSheetLine">The line being counted.</param>
    /// <param name="CountedQuantity">What was found. Zero is a count, not a missing count.</param>
    procedure RecordCount(var CountSheetLine: Record "WHA Count Sheet Line"; CountedQuantity: Decimal);

    /// <summary>
    /// Accepts a difference that is bigger than the tolerance, so the sheet can be closed.
    /// </summary>
    /// <param name="CountSheetLine">The line to approve.</param>
    procedure Approve(var CountSheetLine: Record "WHA Count Sheet Line");
}
