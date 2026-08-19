namespace WarehouseAdvanced.Counting;

codeunit 50501 "WHA Count Line Logic" implements "WHA ICountSheetLine"
{
    Access = Public;

    var
        NotCountableErr: Label 'Count sheet %1 is %2, so nothing on it can be counted. A sheet has to be sent out before it can be counted.', Comment = '%1 = the count sheet number, %2 = the status of the sheet';
        NegativeCountErr: Label 'A counted quantity cannot be negative. Enter zero for a bin you found empty.';
        NotCountedYetErr: Label 'Line %1 on count sheet %2 has not been counted, so there is no difference to approve.', Comment = '%1 = the line number, %2 = the count sheet number';
        WithinToleranceErr: Label 'Line %1 on count sheet %2 is within the tolerance, so it does not need approving.', Comment = '%1 = the line number, %2 = the count sheet number';
        DeleteNotAllowedErr: Label 'A line cannot be removed from count sheet %1 while its status is %2. What was counted is a record.', Comment = '%1 = the count sheet number, %2 = the status of the sheet';

    /// <summary>
    /// Gives a new line its position on the sheet.
    /// </summary>
    /// <param name="CountSheetLine">The line being inserted.</param>
    procedure Trigger_OnInsert(var CountSheetLine: Record "WHA Count Sheet Line")
    var
        ExistingLine: Record "WHA Count Sheet Line";
    begin
        if CountSheetLine."Line No." <> 0 then
            exit;

        ExistingLine.SetLoadFields("Line No.");
        ExistingLine.SetRange("Sheet No.", CountSheetLine."Sheet No.");
        if ExistingLine.FindLast() then
            CountSheetLine."Line No." := ExistingLine."Line No." + 10000
        else
            CountSheetLine."Line No." := 10000;
    end;

    /// <summary>
    /// Refuses to delete a line off a sheet that has left the desk.
    /// </summary>
    /// <param name="CountSheetLine">The line being deleted.</param>
    procedure Trigger_OnDelete(var CountSheetLine: Record "WHA Count Sheet Line")
    var
        CountSheet: Record "WHA Count Sheet";
    begin
        CountSheet.SetLoadFields(Status);
        if not CountSheet.Get(CountSheetLine."Sheet No.") then
            exit;
        if CountSheet.Status in [CountSheet.Status::WHAOpen, CountSheet.Status::WHACancelled] then
            exit;

        Error(DeleteNotAllowedErr, CountSheet."No.", CountSheet.Status);
    end;

    /// <summary>
    /// Works out the difference from what was expected and decides whether it is bigger than the tolerance
    /// allows.
    /// </summary>
    /// <param name="CountSheetLine">The line being counted.</param>
    /// <param name="xCountSheetLine">The line as it was before the count was entered.</param>
    procedure Validate_CountedQuantity(var CountSheetLine: Record "WHA Count Sheet Line"; xCountSheetLine: Record "WHA Count Sheet Line")
    var
        CountSheet: Record "WHA Count Sheet";
    begin
        if CountSheetLine."Counted Quantity" < 0 then
            Error(NegativeCountErr);

        CountSheet.SetLoadFields(Status);
        CountSheet.Get(CountSheetLine."Sheet No.");
        if not (CountSheet.Status in [CountSheet.Status::WHACounting, CountSheet.Status::WHACounted]) then
            Error(NotCountableErr, CountSheet."No.", CountSheet.Status);

        CountSheetLine.Counted := true;
        CountSheetLine.Variance := CountSheetLine."Counted Quantity" - CountSheetLine."Expected Quantity";
        CountSheetLine."Out of Tolerance" := IsOutOfTolerance(CountSheetLine);
        CountSheetLine.Approved := false;
        CountSheetLine."Approved By User ID" := '';
        CountSheetLine."Counted By User ID" := CopyStr(UserId(), 1, MaxStrLen(CountSheetLine."Counted By User ID"));
        CountSheetLine."Counted At" := CurrentDateTime;
    end;

    /// <summary>
    /// Records what was actually found, and saves the line.
    /// </summary>
    /// <param name="CountSheetLine">The line being counted.</param>
    /// <param name="CountedQuantity">What was found.</param>
    procedure RecordCount(var CountSheetLine: Record "WHA Count Sheet Line"; CountedQuantity: Decimal)
    begin
        CountSheetLine.Validate("Counted Quantity", CountedQuantity);
        CountSheetLine.Modify(true);
    end;

    /// <summary>
    /// Accepts a difference that is bigger than the tolerance.
    /// </summary>
    /// <param name="CountSheetLine">The line to approve.</param>
    procedure Approve(var CountSheetLine: Record "WHA Count Sheet Line")
    begin
        if not CountSheetLine.Counted then
            Error(NotCountedYetErr, CountSheetLine."Line No.", CountSheetLine."Sheet No.");
        if not CountSheetLine."Out of Tolerance" then
            Error(WithinToleranceErr, CountSheetLine."Line No.", CountSheetLine."Sheet No.");

        CountSheetLine.Approved := true;
        CountSheetLine."Approved By User ID" := CopyStr(UserId(), 1, MaxStrLen(CountSheetLine."Approved By User ID"));
        CountSheetLine.Modify(true);
    end;

    local procedure IsOutOfTolerance(var CountSheetLine: Record "WHA Count Sheet Line"): Boolean
    var
        Difference: Decimal;
    begin
        Difference := Abs(CountSheetLine.Variance);
        if Difference = 0 then
            exit(false);

        exit(Difference > AllowanceFor(CountSheetLine));
    end;

    local procedure AllowanceFor(var CountSheetLine: Record "WHA Count Sheet Line"): Decimal
    var
        Setup: Record "WHA Count Setup";
        PercentAllowance: Decimal;
    begin
        Setup.SetLoadFields("Tolerance Quantity", "Tolerance Percent");
        if not Setup.Get() then
            exit(0);

        PercentAllowance := Abs(CountSheetLine."Expected Quantity") * Setup."Tolerance Percent" / 100;
        if PercentAllowance > Setup."Tolerance Quantity" then
            exit(PercentAllowance);
        exit(Setup."Tolerance Quantity");
    end;
}
