namespace WarehouseAdvanced.LabourManagement;

interface "WHA ILabourEntry"
{
    /// <summary>
    /// Fills in the date and the person when they were not given, so time recorded by hand is as complete
    /// as time taken from a finished job. Time with no job against it is recorded as time off the jobs,
    /// because that is what it is.
    /// </summary>
    /// <param name="LabourEntry">The entry being inserted.</param>
    procedure Trigger_OnInsert(var LabourEntry: Record "WHA Labour Entry");

    /// <summary>
    /// Refuses negative time, and works out the performance again when the minutes are corrected by hand.
    /// </summary>
    /// <param name="LabourEntry">The entry being validated.</param>
    /// <param name="xLabourEntry">The entry as it was before the change.</param>
    procedure Validate_ActualMinutes(var LabourEntry: Record "WHA Labour Entry"; xLabourEntry: Record "WHA Labour Entry");
}
