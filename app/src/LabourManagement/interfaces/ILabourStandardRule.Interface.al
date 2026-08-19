namespace WarehouseAdvanced.LabourManagement;

interface "WHA ILabourStandardRule"
{
    /// <summary>
    /// Applies the defaults a new labour standard needs.
    /// </summary>
    /// <param name="LabourStandard">The standard being inserted.</param>
    procedure Trigger_OnInsert(var LabourStandard: Record "WHA Labour Standard");

    /// <summary>
    /// Refuses a standard of no time at all, which would make every job that was ever done look
    /// infinitely slow.
    /// </summary>
    /// <param name="LabourStandard">The standard being validated.</param>
    /// <param name="xLabourStandard">The standard as it was before the change.</param>
    procedure Validate_Minutes(var LabourStandard: Record "WHA Labour Standard"; xLabourStandard: Record "WHA Labour Standard");
}
