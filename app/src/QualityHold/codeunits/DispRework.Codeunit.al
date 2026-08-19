namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

codeunit 50557 "WHA Disp. Rework" implements "WHA IHoldDisposition"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The goods can be put right. The unit is opened so its contents can be worked on.';

    /// <summary>
    /// Opens the unit, whatever it was before. Goods that are going to be reworked have to be got at, and
    /// a closed unit is one nobody may add to or take from.
    /// </summary>
    /// <param name="QualityHold">The hold being released.</param>
    /// <param name="HandlingUnit">The handling unit the hold was placed on.</param>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit")
    begin
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

    /// <summary>
    /// Answers whether this decision takes the goods out of stock for good.
    /// </summary>
    /// <returns>False. The goods are still there; they need work doing to them.</returns>
    procedure WritesOffStock(): Boolean
    begin
        exit(false);
    end;
}
