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
    /// Refuses to move the posting date of a sheet that has already been closed, because the date a
    /// difference was posted under is part of what was posted.
    /// </summary>
    /// <param name="CountSheet">The count sheet being changed.</param>
    /// <param name="xCountSheet">The count sheet as it was before the change.</param>
    procedure Validate_PostingDate(var CountSheet: Record "WHA Count Sheet"; xCountSheet: Record "WHA Count Sheet");

    /// <summary>
    /// Puts on a line the things the selection knows and the caller of AddLine cannot pass: what the goods
    /// are called, and which lot or serial number they carry. Without the tracking, a difference on a
    /// tracked item cannot be adjusted at all.
    /// </summary>
    /// <param name="CountSheet">The sheet the line is on.</param>
    /// <param name="LineNo">The line to complete.</param>
    /// <param name="LineDescription">What the goods are, or blank to leave it alone.</param>
    /// <param name="LotNo">The lot the goods belong to, or blank.</param>
    /// <param name="SerialNo">The serial number of the goods, or blank.</param>
    procedure SetLineDetails(var CountSheet: Record "WHA Count Sheet"; LineNo: Integer; LineDescription: Text[100]; LotNo: Code[50]; SerialNo: Code[50]);

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
    /// Closes a counted sheet, once every difference beyond tolerance has been approved, and hands its
    /// differences to the posting method chosen in the counting setup. What the method does with them —
    /// nothing, a journal line, or a ledger entry — is the method's business, not the sheet's.
    /// </summary>
    /// <param name="CountSheet">The sheet to close.</param>
    procedure Close(var CountSheet: Record "WHA Count Sheet");

    /// <summary>
    /// Withdraws a sheet that is no longer wanted, keeping what was counted so far as a record.
    /// </summary>
    /// <param name="CountSheet">The sheet to cancel.</param>
    procedure Cancel(var CountSheet: Record "WHA Count Sheet");
}
