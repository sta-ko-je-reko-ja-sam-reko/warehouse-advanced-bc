namespace WarehouseAdvanced.Counting;

interface "WHA ICountSheet"
{
    /// <summary>
    /// Assigns the number from the foundation series and the defaults a new count sheet needs.
    /// </summary>
    /// <param name="CountSheet">The count sheet being inserted.</param>
    procedure Trigger_OnInsert(var CountSheet: Record "WHA Count Sheet");

    /// <summary>
    /// Refuses to delete a sheet that has been counted or closed, or one that carries a count on any of
    /// its lines, and takes the lines of a sheet that has neither with it.
    /// </summary>
    /// <param name="CountSheet">The count sheet being deleted.</param>
    procedure Trigger_OnDelete(var CountSheet: Record "WHA Count Sheet");

    /// <summary>
    /// Fills an open sheet with what its selection finds at the location, recording what the system
    /// believes is there as the expected quantity.
    /// </summary>
    /// <param name="CountSheet">The sheet to fill.</param>
    /// <returns>How many lines were added.</returns>
    procedure Fill(var CountSheet: Record "WHA Count Sheet"): Integer;

    /// <summary>
    /// Puts one line on a sheet. Used by the selections and by anyone adding a line by hand.
    /// </summary>
    /// <param name="CountSheet">The sheet to add to.</param>
    /// <param name="BinCode">The bin being counted.</param>
    /// <param name="ItemNo">The item being counted.</param>
    /// <param name="VariantCode">The item variant being counted.</param>
    /// <param name="UnitOfMeasureCode">The unit the count is entered in.</param>
    /// <param name="HandlingUnitNo">The handling unit the line covers, if any.</param>
    /// <param name="ExpectedQuantity">What the system believes is there.</param>
    /// <returns>The line number of the line that was added.</returns>
    procedure AddLine(var CountSheet: Record "WHA Count Sheet"; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; HandlingUnitNo: Code[20]; ExpectedQuantity: Decimal): Integer;

    /// <summary>
    /// Sends the sheet to the floor. From here the expected quantities are fixed, so what is counted is
    /// compared against what was believed when the count was ordered.
    /// </summary>
    /// <param name="CountSheet">The sheet to start.</param>
    procedure Start(var CountSheet: Record "WHA Count Sheet");

    /// <summary>
    /// Marks a sheet whose every line has been counted as counted, and refuses one that still has lines
    /// outstanding.
    /// </summary>
    /// <param name="CountSheet">The sheet to complete.</param>
    procedure Complete(var CountSheet: Record "WHA Count Sheet");

    /// <summary>
    /// Marks a sheet as counted when every line has been counted, and does nothing to one that has not.
    /// Safe to call on anything.
    /// </summary>
    /// <param name="CountSheet">The sheet to look at.</param>
    /// <returns>True when the sheet was marked counted by this call.</returns>
    procedure CompleteIfCounted(var CountSheet: Record "WHA Count Sheet"): Boolean;

    /// <summary>
    /// Closes a counted sheet, once every difference beyond tolerance has been approved.
    /// </summary>
    /// <param name="CountSheet">The sheet to close.</param>
    procedure Close(var CountSheet: Record "WHA Count Sheet");

    /// <summary>
    /// Withdraws a sheet that is no longer wanted, keeping what was counted so far as a record.
    /// </summary>
    /// <param name="CountSheet">The sheet to cancel.</param>
    procedure Cancel(var CountSheet: Record "WHA Count Sheet");
}
