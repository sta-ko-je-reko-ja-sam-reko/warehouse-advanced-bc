namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

codeunit 50551 "WHA Quality Hold Mgt."
{
    Access = Public;

    var
        UnitShippedErr: Label 'Handling unit %1 has already been shipped, so it cannot be put on hold.', Comment = '%1 = the handling unit number';
        UnitScrappedErr: Label 'Handling unit %1 has been scrapped, so there is nothing left to hold.', Comment = '%1 = the handling unit number';
        AlreadyHeldErr: Label 'Handling unit %1 is already on hold, under hold %2.', Comment = '%1 = the handling unit number, %2 = the entry number of the hold that is already on it';
        UnitMissingErr: Label 'Handling unit %1 does not exist, so it cannot be put on hold.', Comment = '%1 = the handling unit number';
        AlreadyReleasedErr: Label 'Hold %1 was released on %2, so it cannot be released again.', Comment = '%1 = the hold entry number, %2 = when it was released';
        CascadedHoldErr: Label 'Hold %1 exists because the unit was inside the unit held by hold %2. Release hold %2, and this one goes with it.', Comment = '%1 = this hold entry number, %2 = the entry number of the hold that brought it with it';
        UnitGoneErr: Label 'Handling unit %1 no longer exists, so hold %2 cannot be released. The hold stays as the record that it was placed.', Comment = '%1 = the handling unit number, %2 = the hold entry number';

    /// <summary>
    /// Stops a handling unit from being used, and everything nested inside it when the setup asks for
    /// that. Each unit gets its own hold record, so what was stopped and why can be answered per unit
    /// rather than per pallet.
    /// </summary>
    /// <param name="HandlingUnit">The handling unit to stop.</param>
    /// <param name="Reason">Why it is being stopped.</param>
    /// <param name="HoldDescription">What was found, in the words of whoever found it.</param>
    /// <returns>The entry number of the hold placed on the named unit.</returns>
    procedure Place(var HandlingUnit: Record "WHA Handling Unit"; Reason: Enum "WHA Hold Reason"; HoldDescription: Text[100]): Integer
    var
        ExistingHold: Record "WHA Quality Hold";
        EntryNo: Integer;
    begin
        if not HandlingUnit.Get(HandlingUnit."No.") then
            Error(UnitMissingErr, HandlingUnit."No.");
        if HandlingUnit.Status = HandlingUnit.Status::WHAShipped then
            Error(UnitShippedErr, HandlingUnit."No.");
        if HandlingUnit.Status = HandlingUnit.Status::WHAScrapped then
            Error(UnitScrappedErr, HandlingUnit."No.");
        if ActiveHold(HandlingUnit."No.", ExistingHold) then
            Error(AlreadyHeldErr, HandlingUnit."No.", ExistingHold."Entry No.");

        EntryNo := InsertHold(HandlingUnit, Reason, HoldDescription, 0);
        StopUnit(HandlingUnit);

        if HoldsNestedUnits() then
            CascadeToNested(HandlingUnit, EntryNo, Reason, HoldDescription);

        exit(EntryNo);
    end;

    /// <summary>
    /// Says what happens to the goods, while the hold is still on. Deciding is deliberately separate from
    /// releasing: the decision is somebody's judgement about the goods, and lifting the hold is the moment
    /// it takes effect.
    /// </summary>
    /// <param name="QualityHold">The hold to decide on.</param>
    /// <param name="NewDisposition">What should happen to the goods.</param>
    procedure Decide(var QualityHold: Record "WHA Quality Hold"; NewDisposition: Enum "WHA Hold Disposition")
    begin
        QualityHold.Validate(Disposition, NewDisposition);
        QualityHold.Modify(true);
    end;

    /// <summary>
    /// Lifts the hold and carries out the decision, on the unit and on everything that was held with it.
    /// Goods a decision takes out of stock for good are written off by the posting method chosen in the
    /// quality hold setup, each unit under its own document, because each unit carries its own hold.
    /// </summary>
    /// <param name="QualityHold">The hold to release.</param>
    procedure Release(var QualityHold: Record "WHA Quality Hold")
    var
        Disposition: Enum "WHA Hold Disposition";
    begin
        if QualityHold.Status = QualityHold.Status::WHAReleased then
            Error(AlreadyReleasedErr, QualityHold."Entry No.", QualityHold."Released At");
        if QualityHold."Cascaded From Entry No." <> 0 then
            Error(CascadedHoldErr, QualityHold."Entry No.", QualityHold."Cascaded From Entry No.");

        Disposition := DispositionToApply(QualityHold);

        ApplyAndClose(QualityHold, Disposition);
        ReleaseCascaded(QualityHold, Disposition);
    end;

    /// <summary>
    /// Answers whether a handling unit is on hold right now.
    /// </summary>
    /// <param name="HandlingUnitNo">The handling unit to ask about.</param>
    /// <returns>True when a hold is on it.</returns>
    procedure IsOnHold(HandlingUnitNo: Code[20]): Boolean
    var
        QualityHold: Record "WHA Quality Hold";
    begin
        exit(ActiveHold(HandlingUnitNo, QualityHold));
    end;

    /// <summary>
    /// Finds the hold that is on a handling unit right now, if there is one.
    /// </summary>
    /// <param name="HandlingUnitNo">The handling unit to ask about.</param>
    /// <param name="QualityHold">Receives the hold that is on it.</param>
    /// <returns>True when a hold is on it.</returns>
    procedure ActiveHold(HandlingUnitNo: Code[20]; var QualityHold: Record "WHA Quality Hold"): Boolean
    begin
        QualityHold.Reset();
        QualityHold.SetCurrentKey("Handling Unit No.", Status);
        QualityHold.SetRange("Handling Unit No.", HandlingUnitNo);
        QualityHold.SetRange(Status, QualityHold.Status::WHAOnHold);
        exit(QualityHold.FindFirst());
    end;

    /// <summary>
    /// Answers the reason a hold is given when whoever placed it did not choose one.
    /// </summary>
    /// <returns>The reason from the quality hold setup.</returns>
    procedure DefaultReason(): Enum "WHA Hold Reason"
    var
        Setup: Record "WHA Quality Hold Setup";
        Reason: Enum "WHA Hold Reason";
    begin
        Setup.SetLoadFields("Default Reason");
        if not Setup.Get() then
            exit(Reason::WHAInspection);
        exit(Setup."Default Reason");
    end;

    /// <summary>
    /// Describes in one line what the hold's decision would do to the goods.
    /// </summary>
    /// <param name="QualityHold">The hold to describe.</param>
    /// <returns>A short description in the user's language.</returns>
    procedure DescribeDisposition(var QualityHold: Record "WHA Quality Hold"): Text
    var
        HoldDisposition: Interface "WHA IHoldDisposition";
    begin
        HoldDisposition := QualityHold.Disposition;
        exit(HoldDisposition.Describe());
    end;

    local procedure CascadeToNested(ParentUnit: Record "WHA Handling Unit"; SourceEntryNo: Integer; Reason: Enum "WHA Hold Reason"; HoldDescription: Text[100])
    var
        NestedUnit: Record "WHA Handling Unit";
    begin
        NestedUnit.SetCurrentKey("Parent No.");
        NestedUnit.SetRange("Parent No.", ParentUnit."No.");
        if not NestedUnit.FindSet() then
            exit;

        repeat
            if IsHoldable(NestedUnit) then begin
                InsertHold(NestedUnit, Reason, HoldDescription, SourceEntryNo);
                StopUnit(NestedUnit);
            end;
            CascadeToNested(NestedUnit, SourceEntryNo, Reason, HoldDescription);
        until NestedUnit.Next() = 0;
    end;

    local procedure ReleaseCascaded(var QualityHold: Record "WHA Quality Hold"; Disposition: Enum "WHA Hold Disposition")
    var
        CascadedHold: Record "WHA Quality Hold";
    begin
        CascadedHold.SetCurrentKey("Cascaded From Entry No.");
        CascadedHold.SetRange("Cascaded From Entry No.", QualityHold."Entry No.");
        CascadedHold.SetRange(Status, CascadedHold.Status::WHAOnHold);
        if not CascadedHold.FindSet() then
            exit;

        repeat
            ApplyAndClose(CascadedHold, Disposition);
        until CascadedHold.Next() = 0;
    end;

    local procedure ApplyAndClose(var QualityHold: Record "WHA Quality Hold"; Disposition: Enum "WHA Hold Disposition")
    var
        QCPosting: Codeunit "WHA QC Posting";
    begin
        ApplyTo(QualityHold, Disposition);
        QCPosting.PostWriteOff(QualityHold, Disposition);
        CloseHold(QualityHold, Disposition);
    end;

    local procedure ApplyTo(var QualityHold: Record "WHA Quality Hold"; Disposition: Enum "WHA Hold Disposition")
    var
        HandlingUnit: Record "WHA Handling Unit";
        HoldDisposition: Interface "WHA IHoldDisposition";
    begin
        if not HandlingUnit.Get(QualityHold."Handling Unit No.") then
            Error(UnitGoneErr, QualityHold."Handling Unit No.", QualityHold."Entry No.");

        HoldDisposition := Disposition;
        HoldDisposition.Apply(QualityHold, HandlingUnit);
    end;

    local procedure CloseHold(var QualityHold: Record "WHA Quality Hold"; Disposition: Enum "WHA Hold Disposition")
    begin
        QualityHold.Disposition := Disposition;
        QualityHold.Status := QualityHold.Status::WHAReleased;
        QualityHold."Released By User ID" := CopyStr(UserId(), 1, MaxStrLen(QualityHold."Released By User ID"));
        QualityHold."Released At" := CurrentDateTime;
        QualityHold.Modify(true);
    end;

    local procedure DispositionToApply(var QualityHold: Record "WHA Quality Hold"): Enum "WHA Hold Disposition"
    var
        Disposition: Enum "WHA Hold Disposition";
    begin
        if QualityHold.Disposition <> QualityHold.Disposition::WHAPending then
            exit(QualityHold.Disposition);
        if RequiresDisposition() then
            exit(QualityHold.Disposition);

        exit(Disposition::WHAReleaseToStock);
    end;

    local procedure InsertHold(var HandlingUnit: Record "WHA Handling Unit"; Reason: Enum "WHA Hold Reason"; HoldDescription: Text[100]; SourceEntryNo: Integer): Integer
    var
        QualityHold: Record "WHA Quality Hold";
    begin
        QualityHold.Init();
        QualityHold."Handling Unit No." := HandlingUnit."No.";
        QualityHold.Validate(Reason, Reason);
        QualityHold.Validate(Description, HoldDescription);
        QualityHold."Cascaded From Entry No." := SourceEntryNo;
        QualityHold.Insert(true);
        exit(QualityHold."Entry No.");
    end;

    local procedure StopUnit(var HandlingUnit: Record "WHA Handling Unit")
    begin
        HandlingUnit.Validate(Status, HandlingUnit.Status::WHAOnHold);
        HandlingUnit.Modify(true);
    end;

    local procedure IsHoldable(var HandlingUnit: Record "WHA Handling Unit"): Boolean
    begin
        if HandlingUnit.Status in [HandlingUnit.Status::WHAShipped, HandlingUnit.Status::WHAScrapped, HandlingUnit.Status::WHAOnHold] then
            exit(false);
        exit(not IsOnHold(HandlingUnit."No."));
    end;

    local procedure HoldsNestedUnits(): Boolean
    var
        Setup: Record "WHA Quality Hold Setup";
    begin
        Setup.SetLoadFields("Hold Nested Units");
        if not Setup.Get() then
            exit(true);
        exit(Setup."Hold Nested Units");
    end;

    local procedure RequiresDisposition(): Boolean
    var
        Setup: Record "WHA Quality Hold Setup";
    begin
        Setup.SetLoadFields("Require Disposition");
        if not Setup.Get() then
            exit(true);
        exit(Setup."Require Disposition");
    end;
}
