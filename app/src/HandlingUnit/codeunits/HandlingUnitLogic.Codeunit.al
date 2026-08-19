namespace WarehouseAdvanced.HandlingUnit;

using Microsoft.Foundation.NoSeries;
using WarehouseAdvanced.Core;

codeunit 50050 "WHA Handling Unit Logic" implements "WHA IHandlingUnit"
{
    Access = Public;

    var
        NoSeriesMissingErr: Label 'Set the handling unit number series in the warehouse advanced setup before creating handling units.';
        SelfParentErr: Label 'A handling unit cannot be placed inside itself.';
        CycleErr: Label 'Handling unit %1 cannot be placed inside %2, because %2 is already inside %1.', Comment = '%1 = the handling unit being changed, %2 = the proposed parent handling unit';
        NestingNotAllowedErr: Label 'Nesting is switched off in the handling unit setup, so %1 cannot be placed inside another handling unit.', Comment = '%1 = the handling unit being changed';
        DepthExceededErr: Label 'Placing %1 inside %2 would exceed the maximum nesting depth of %3.', Comment = '%1 = the handling unit being changed, %2 = the proposed parent, %3 = the configured maximum depth';
        HasNestedUnitsErr: Label 'Handling unit %1 cannot be deleted while it still holds %2 nested unit(s).', Comment = '%1 = the handling unit number, %2 = how many units are inside it';

    /// <summary>
    /// Assigns the number series value and any defaults a new handling unit needs.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit being inserted.</param>
    procedure Trigger_OnInsert(var HandlingUnit: Record "WHA Handling Unit")
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if HandlingUnit."No." <> '' then
            exit;

        WarehouseSetup.SetLoadFields("Handling Unit Nos.");
        if not WarehouseSetup.Get() then
            Error(NoSeriesMissingErr);
        if WarehouseSetup."Handling Unit Nos." = '' then
            Error(NoSeriesMissingErr);

        HandlingUnit."No." := NoSeries.GetNextNo(WarehouseSetup."Handling Unit Nos.");
    end;

    /// <summary>
    /// Refuses the delete when the handling unit still holds nested units.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit being deleted.</param>
    procedure Trigger_OnDelete(var HandlingUnit: Record "WHA Handling Unit")
    var
        Nested: Record "WHA Handling Unit";
    begin
        Nested.SetLoadFields("No.");
        Nested.SetRange("Parent No.", HandlingUnit."No.");
        if not Nested.IsEmpty() then
            Error(HasNestedUnitsErr, HandlingUnit."No.", Nested.Count());
    end;

    /// <summary>
    /// Clears the bin when the location changes, so a bin from the previous location cannot be kept.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit being validated.</param>
    /// <param name="xHandlingUnit">The handling unit as it was before the change.</param>
    procedure Validate_LocationCode(var HandlingUnit: Record "WHA Handling Unit"; xHandlingUnit: Record "WHA Handling Unit")
    begin
        if HandlingUnit."Location Code" = xHandlingUnit."Location Code" then
            exit;
        HandlingUnit."Bin Code" := '';
    end;

    /// <summary>
    /// Rejects a parent that would nest a unit inside itself, form a cycle, or exceed the configured
    /// nesting depth.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit being validated.</param>
    /// <param name="xHandlingUnit">The handling unit as it was before the change.</param>
    procedure Validate_ParentNo(var HandlingUnit: Record "WHA Handling Unit"; xHandlingUnit: Record "WHA Handling Unit")
    var
        Setup: Record "WHA Handling Unit Setup";
        Depth: Integer;
    begin
        if HandlingUnit."Parent No." = xHandlingUnit."Parent No." then
            exit;
        if HandlingUnit."Parent No." = '' then
            exit;

        if HandlingUnit."Parent No." = HandlingUnit."No." then
            Error(SelfParentErr);

        Setup.SetLoadFields("Allow Nesting", "Max Nesting Depth");
        if Setup.Get() then begin
            if not Setup."Allow Nesting" then
                Error(NestingNotAllowedErr, HandlingUnit."No.");

            if Setup."Max Nesting Depth" > 0 then begin
                Depth := DepthOf(HandlingUnit."Parent No.") + 1;
                if Depth > Setup."Max Nesting Depth" then
                    Error(DepthExceededErr, HandlingUnit."No.", HandlingUnit."Parent No.", Setup."Max Nesting Depth");
            end;
        end;

        if IsDescendantOf(HandlingUnit."Parent No.", HandlingUnit."No.") then
            Error(CycleErr, HandlingUnit."No.", HandlingUnit."Parent No.");
    end;

    /// <summary>
    /// Calculates how deep a handling unit sits in the nesting hierarchy.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit to measure.</param>
    /// <returns>Zero for a unit with no parent, one for a unit inside a top-level unit, and so on.</returns>
    procedure GetNestingDepth(var HandlingUnit: Record "WHA Handling Unit"): Integer
    begin
        exit(DepthOf(HandlingUnit."Parent No."));
    end;

    local procedure DepthOf(ParentNo: Code[20]): Integer
    var
        Parent: Record "WHA Handling Unit";
        Depth: Integer;
        Guard: Integer;
    begin
        Depth := 0;
        Guard := 0;
        while (ParentNo <> '') and (Guard < MaxWalk()) do begin
            Parent.SetLoadFields("Parent No.");
            if not Parent.Get(ParentNo) then
                exit(Depth);
            Depth += 1;
            Guard += 1;
            ParentNo := Parent."Parent No.";
        end;
        exit(Depth);
    end;

    local procedure IsDescendantOf(CandidateNo: Code[20]; AncestorNo: Code[20]): Boolean
    var
        Walker: Record "WHA Handling Unit";
        Guard: Integer;
    begin
        Guard := 0;
        while (CandidateNo <> '') and (Guard < MaxWalk()) do begin
            if CandidateNo = AncestorNo then
                exit(true);
            Walker.SetLoadFields("Parent No.");
            if not Walker.Get(CandidateNo) then
                exit(false);
            CandidateNo := Walker."Parent No.";
            Guard += 1;
        end;
        exit(false);
    end;

    local procedure MaxWalk(): Integer
    begin
        exit(100);
    end;
}
