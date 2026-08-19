namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

codeunit 50558 "WHA Disp. Scrap" implements "WHA IHoldDisposition"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The goods are written off. The unit is marked as scrapped and never comes back into use. Nothing is posted.';

    /// <summary>
    /// Marks the unit as scrapped, which keeps it out of every queue, worksheet and measurement in the
    /// app. It does not post an inventory write-off — see the feature documentation.
    /// </summary>
    /// <param name="QualityHold">The hold being released.</param>
    /// <param name="HandlingUnit">The handling unit the hold was placed on.</param>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit")
    begin
        HandlingUnit.Validate(Status, HandlingUnit.Status::WHAScrapped);
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
    /// <returns>False.</returns>
    procedure ReturnsToUse(): Boolean
    begin
        exit(false);
    end;
}
