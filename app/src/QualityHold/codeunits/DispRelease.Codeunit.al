namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

codeunit 50556 "WHA Disp. Release" implements "WHA IHoldDisposition"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The goods are fine. The unit goes back to what it was before it was stopped.';

    /// <summary>
    /// Puts the unit back to the state it was in before the hold, rather than to a fixed state: a pallet
    /// that was closed and ready to ship when somebody stopped it is closed and ready to ship again, and
    /// releasing it must not quietly reopen it.
    /// </summary>
    /// <param name="QualityHold">The hold being released.</param>
    /// <param name="HandlingUnit">The handling unit the hold was placed on.</param>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit")
    begin
        if QualityHold."Previous Unit Status" in [HandlingUnit.Status::WHAOpen, HandlingUnit.Status::WHAClosed] then
            HandlingUnit.Validate(Status, QualityHold."Previous Unit Status")
        else
            HandlingUnit.Validate(Status, HandlingUnit.Status::WHAOpen);
        HandlingUnit.Modify(true);
    end;

    /// <summary>
    /// Describes in one line what this decision does to the goods.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Answers whether this decision puts the goods back into use.
    /// </summary>
    /// <returns>True.</returns>
    procedure ReturnsToUse(): Boolean
    begin
        exit(true);
    end;
}
