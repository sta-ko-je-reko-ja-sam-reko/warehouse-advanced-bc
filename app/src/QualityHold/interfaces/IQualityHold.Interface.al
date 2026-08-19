namespace WarehouseAdvanced.QualityHold;

interface "WHA IQualityHold"
{
    /// <summary>
    /// Stamps who placed the hold and when, and takes a copy of where the goods were standing at that
    /// moment. The snapshot is the point: a hold is a record of a decision taken at a place and a time,
    /// and the unit may be somewhere else by the time anybody reads it.
    /// </summary>
    /// <param name="QualityHold">The hold being inserted.</param>
    procedure Trigger_OnInsert(var QualityHold: Record "WHA Quality Hold");

    /// <summary>
    /// Refuses a decision on a hold that has already been lifted. What happened to the goods is then a
    /// matter of record, not of opinion.
    /// </summary>
    /// <param name="QualityHold">The hold being validated.</param>
    /// <param name="xQualityHold">The hold as it was before the change.</param>
    procedure Validate_Disposition(var QualityHold: Record "WHA Quality Hold"; xQualityHold: Record "WHA Quality Hold");

    /// <summary>
    /// Refuses the delete. A hold is an audit trail of goods somebody stopped from being used, and an
    /// audit trail that can be deleted is not one.
    /// </summary>
    /// <param name="QualityHold">The hold being deleted.</param>
    procedure Trigger_OnDelete(var QualityHold: Record "WHA Quality Hold");
}
