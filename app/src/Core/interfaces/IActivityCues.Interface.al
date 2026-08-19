namespace WarehouseAdvanced.Core;

interface "WHA IActivityCues"
{
    /// <summary>
    /// Adds this feature's counts to the results the role centre is waiting for. An implementation reads
    /// and counts; it never writes, because it runs in a read-only background session.
    /// </summary>
    /// <param name="Results">The result buffer, keyed by the cue field number each count belongs to.</param>
    procedure AddCounts(var Results: Dictionary of [Text, Text]);
}
