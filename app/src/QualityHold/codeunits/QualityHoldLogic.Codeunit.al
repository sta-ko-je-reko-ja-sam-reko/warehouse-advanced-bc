namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

codeunit 50550 "WHA Quality Hold Logic" implements "WHA IQualityHold"
{
    Access = Public;

    var
        DecideAfterReleaseErr: Label 'Hold %1 has been released, so what happens to the goods can no longer be changed.', Comment = '%1 = the hold entry number';
        DeleteNotAllowedErr: Label 'Hold %1 cannot be deleted. It is the record of goods somebody stopped from being used, and it stays whether or not the hold is still on.', Comment = '%1 = the hold entry number';

    /// <summary>
    /// Stamps who placed the hold and when, and takes a copy of where the goods were standing.
    /// </summary>
    /// <param name="QualityHold">The hold being inserted.</param>
    procedure Trigger_OnInsert(var QualityHold: Record "WHA Quality Hold")
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        QualityHold."Held By User ID" := CopyStr(UserId(), 1, MaxStrLen(QualityHold."Held By User ID"));
        QualityHold."Held At" := CurrentDateTime;

        HandlingUnit.SetLoadFields("Location Code", "Bin Code", Status);
        if not HandlingUnit.Get(QualityHold."Handling Unit No.") then
            exit;

        QualityHold."Location Code" := HandlingUnit."Location Code";
        QualityHold."Bin Code" := HandlingUnit."Bin Code";
        QualityHold."Previous Unit Status" := HandlingUnit.Status;
    end;

    /// <summary>
    /// Refuses a decision on a hold that has already been lifted.
    /// </summary>
    /// <param name="QualityHold">The hold being validated.</param>
    /// <param name="xQualityHold">The hold as it was before the change.</param>
    procedure Validate_Disposition(var QualityHold: Record "WHA Quality Hold"; xQualityHold: Record "WHA Quality Hold")
    begin
        if QualityHold.Disposition = xQualityHold.Disposition then
            exit;
        if QualityHold.Status <> QualityHold.Status::WHAReleased then
            exit;

        Error(DecideAfterReleaseErr, QualityHold."Entry No.");
    end;

    /// <summary>
    /// Refuses the delete.
    /// </summary>
    /// <param name="QualityHold">The hold being deleted.</param>
    procedure Trigger_OnDelete(var QualityHold: Record "WHA Quality Hold")
    begin
        Error(DeleteNotAllowedErr, QualityHold."Entry No.");
    end;
}
