namespace WarehouseAdvanced.Counting;

using Microsoft.Foundation.NoSeries;
using WarehouseAdvanced.Core;

codeunit 50500 "WHA Count Sheet Logic" implements "WHA ICountSheet"
{
    Access = Public;

    var
        NoSeriesMissingErr: Label 'Set the count sheet number series in the warehouse advanced setup before creating count sheets.';
        NotOpenErr: Label 'Count sheet %1 is %2, so what it covers can no longer be changed.', Comment = '%1 = the count sheet number, %2 = the current status';
        LocationMissingErr: Label 'Give count sheet %1 a location before filling it, so it counts one part of the warehouse.', Comment = '%1 = the count sheet number';
        StartNotAllowedErr: Label 'Only an open count sheet can be sent out to be counted. Count sheet %1 is %2.', Comment = '%1 = the count sheet number, %2 = the current status';
        EmptySheetErr: Label 'Count sheet %1 has no lines, so there is nothing to count.', Comment = '%1 = the count sheet number';
        NotCountingErr: Label 'Count sheet %1 is %2, so it cannot be completed. Only a sheet that is being counted can be.', Comment = '%1 = the count sheet number, %2 = the current status';
        StillCountingErr: Label 'Count sheet %1 still has %2 line(s) nobody has counted.', Comment = '%1 = the count sheet number, %2 = how many lines are not counted';
        CloseNotAllowedErr: Label 'Only a counted sheet can be closed. Count sheet %1 is %2.', Comment = '%1 = the count sheet number, %2 = the current status';
        UnapprovedErr: Label 'Count sheet %1 has %2 difference(s) beyond the tolerance that nobody has approved.', Comment = '%1 = the count sheet number, %2 = how many lines are waiting for approval';
        CancelNotAllowedErr: Label 'Count sheet %1 is already %2, so it cannot be cancelled.', Comment = '%1 = the count sheet number, %2 = the current status';
        DeleteNotAllowedErr: Label 'Count sheet %1 cannot be deleted while its status is %2. Cancel it instead, so the record of what was counted is kept.', Comment = '%1 = the count sheet number, %2 = the current status';
        CountedLinesErr: Label 'Count sheet %1 has lines that have been counted, so it cannot be deleted. What somebody found is a record.', Comment = '%1 = the count sheet number';

    /// <summary>
    /// Assigns the number from the foundation series and the defaults a new count sheet needs.
    /// </summary>
    /// <param name="CountSheet">The count sheet being inserted.</param>
    procedure Trigger_OnInsert(var CountSheet: Record "WHA Count Sheet")
    var
        Setup: Record "WHA Count Setup";
    begin
        if CountSheet."No." = '' then
            CountSheet."No." := NextSheetNo();

        Setup.SetLoadFields("Default Selection", "Blind Counting");
        if not Setup.Get() then
            exit;

        if CountSheet.Selection = CountSheet.Selection::WHABinContent then
            CountSheet.Selection := Setup."Default Selection";
        if not CountSheet.Blind then
            CountSheet.Blind := Setup."Blind Counting";
    end;

    /// <summary>
    /// Refuses to delete a sheet that has been counted or closed, or one that carries a count on any of
    /// its lines, and takes the lines of a sheet that has neither with it.
    /// </summary>
    /// <param name="CountSheet">The count sheet being deleted.</param>
    procedure Trigger_OnDelete(var CountSheet: Record "WHA Count Sheet")
    var
        CountSheetLine: Record "WHA Count Sheet Line";
    begin
        if CountSheet.Status in [CountSheet.Status::WHACounted, CountSheet.Status::WHAClosed] then
            Error(DeleteNotAllowedErr, CountSheet."No.", CountSheet.Status);

        CountSheetLine.SetCurrentKey("Sheet No.", Counted);
        CountSheetLine.SetRange("Sheet No.", CountSheet."No.");
        CountSheetLine.SetRange(Counted, true);
        if not CountSheetLine.IsEmpty() then
            Error(CountedLinesErr, CountSheet."No.");

        CountSheetLine.SetRange(Counted);
        CountSheetLine.DeleteAll(false);
    end;

    /// <summary>
    /// Fills an open sheet with what its selection finds at the location.
    /// </summary>
    /// <param name="CountSheet">The sheet to fill.</param>
    /// <returns>How many lines were added.</returns>
    procedure Fill(var CountSheet: Record "WHA Count Sheet"): Integer
    var
        CountSelection: Interface "WHA ICountSelection";
    begin
        CheckOpen(CountSheet);
        if CountSheet."Location Code" = '' then
            Error(LocationMissingErr, CountSheet."No.");

        CountSelection := CountSheet.Selection;
        exit(CountSelection.Fill(CountSheet));
    end;

    /// <summary>
    /// Puts one line on a sheet.
    /// </summary>
    /// <param name="CountSheet">The sheet to add to.</param>
    /// <param name="BinCode">The bin being counted.</param>
    /// <param name="ItemNo">The item being counted.</param>
    /// <param name="VariantCode">The item variant being counted.</param>
    /// <param name="UnitOfMeasureCode">The unit the count is entered in.</param>
    /// <param name="HandlingUnitNo">The handling unit the line covers, if any.</param>
    /// <param name="ExpectedQuantity">What the system believes is there.</param>
    /// <returns>The line number of the line that was added.</returns>
    procedure AddLine(var CountSheet: Record "WHA Count Sheet"; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; HandlingUnitNo: Code[20]; ExpectedQuantity: Decimal): Integer
    var
        CountSheetLine: Record "WHA Count Sheet Line";
    begin
        CheckOpen(CountSheet);

        CountSheetLine.Init();
        CountSheetLine."Sheet No." := CountSheet."No.";
        CountSheetLine."Bin Code" := BinCode;
        CountSheetLine."Item No." := ItemNo;
        CountSheetLine."Variant Code" := VariantCode;
        CountSheetLine."Unit of Measure Code" := UnitOfMeasureCode;
        CountSheetLine."Handling Unit No." := HandlingUnitNo;
        CountSheetLine."Expected Quantity" := ExpectedQuantity;
        CountSheetLine.Insert(true);

        exit(CountSheetLine."Line No.");
    end;

    /// <summary>
    /// Sends the sheet to the floor.
    /// </summary>
    /// <param name="CountSheet">The sheet to start.</param>
    procedure Start(var CountSheet: Record "WHA Count Sheet")
    var
        CountSheetLine: Record "WHA Count Sheet Line";
    begin
        if CountSheet.Status <> CountSheet.Status::WHAOpen then
            Error(StartNotAllowedErr, CountSheet."No.", CountSheet.Status);

        CountSheetLine.SetRange("Sheet No.", CountSheet."No.");
        if CountSheetLine.IsEmpty() then
            Error(EmptySheetErr, CountSheet."No.");

        CountSheet.Status := CountSheet.Status::WHACounting;
        CountSheet."Started At" := CurrentDateTime;
        CountSheet.Modify(true);
    end;

    /// <summary>
    /// Marks a sheet whose every line has been counted as counted.
    /// </summary>
    /// <param name="CountSheet">The sheet to complete.</param>
    procedure Complete(var CountSheet: Record "WHA Count Sheet")
    var
        Outstanding: Integer;
    begin
        if CountSheet.Status <> CountSheet.Status::WHACounting then
            Error(NotCountingErr, CountSheet."No.", CountSheet.Status);

        Outstanding := UncountedCount(CountSheet);
        if Outstanding > 0 then
            Error(StillCountingErr, CountSheet."No.", Outstanding);

        MarkCounted(CountSheet);
    end;

    /// <summary>
    /// Marks a sheet as counted when every line has been counted, and does nothing to one that has not.
    /// </summary>
    /// <param name="CountSheet">The sheet to look at.</param>
    /// <returns>True when the sheet was marked counted by this call.</returns>
    procedure CompleteIfCounted(var CountSheet: Record "WHA Count Sheet"): Boolean
    begin
        if CountSheet.Status <> CountSheet.Status::WHACounting then
            exit(false);
        if UncountedCount(CountSheet) > 0 then
            exit(false);

        MarkCounted(CountSheet);
        exit(true);
    end;

    /// <summary>
    /// Closes a counted sheet, once every difference beyond tolerance has been approved.
    /// </summary>
    /// <param name="CountSheet">The sheet to close.</param>
    procedure Close(var CountSheet: Record "WHA Count Sheet")
    var
        Waiting: Integer;
    begin
        if CountSheet.Status <> CountSheet.Status::WHACounted then
            Error(CloseNotAllowedErr, CountSheet."No.", CountSheet.Status);

        if ApprovalRequired() then begin
            Waiting := UnapprovedCount(CountSheet);
            if Waiting > 0 then
                Error(UnapprovedErr, CountSheet."No.", Waiting);
        end;

        CountSheet.Status := CountSheet.Status::WHAClosed;
        CountSheet."Closed At" := CurrentDateTime;
        CountSheet.Modify(true);
    end;

    /// <summary>
    /// Withdraws a sheet that is no longer wanted.
    /// </summary>
    /// <param name="CountSheet">The sheet to cancel.</param>
    procedure Cancel(var CountSheet: Record "WHA Count Sheet")
    begin
        if CountSheet.Status in [CountSheet.Status::WHAClosed, CountSheet.Status::WHACancelled] then
            Error(CancelNotAllowedErr, CountSheet."No.", CountSheet.Status);

        CountSheet.Status := CountSheet.Status::WHACancelled;
        CountSheet.Modify(true);
    end;

    local procedure MarkCounted(var CountSheet: Record "WHA Count Sheet")
    begin
        CountSheet.Status := CountSheet.Status::WHACounted;
        CountSheet."Counted At" := CurrentDateTime;
        CountSheet.Modify(true);
    end;

    local procedure UncountedCount(var CountSheet: Record "WHA Count Sheet"): Integer
    var
        CountSheetLine: Record "WHA Count Sheet Line";
    begin
        CountSheetLine.SetCurrentKey("Sheet No.", Counted);
        CountSheetLine.SetRange("Sheet No.", CountSheet."No.");
        CountSheetLine.SetRange(Counted, false);
        exit(CountSheetLine.Count());
    end;

    local procedure UnapprovedCount(var CountSheet: Record "WHA Count Sheet"): Integer
    var
        CountSheetLine: Record "WHA Count Sheet Line";
    begin
        CountSheetLine.SetRange("Sheet No.", CountSheet."No.");
        CountSheetLine.SetRange("Out of Tolerance", true);
        CountSheetLine.SetRange(Approved, false);
        exit(CountSheetLine.Count());
    end;

    local procedure ApprovalRequired(): Boolean
    var
        Setup: Record "WHA Count Setup";
    begin
        Setup.SetLoadFields("Approve Variances");
        if not Setup.Get() then
            exit(true);
        exit(Setup."Approve Variances");
    end;

    local procedure CheckOpen(var CountSheet: Record "WHA Count Sheet")
    begin
        if CountSheet.Status <> CountSheet.Status::WHAOpen then
            Error(NotOpenErr, CountSheet."No.", CountSheet.Status);
    end;

    local procedure NextSheetNo(): Code[20]
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        WarehouseSetup.SetLoadFields("Count Sheet Nos.");
        if not WarehouseSetup.Get() then
            Error(NoSeriesMissingErr);
        if WarehouseSetup."Count Sheet Nos." = '' then
            Error(NoSeriesMissingErr);

        exit(NoSeries.GetNextNo(WarehouseSetup."Count Sheet Nos."));
    end;
}
