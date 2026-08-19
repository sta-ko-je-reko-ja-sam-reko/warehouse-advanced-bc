namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.DirectedWork;

interface "WHA IWaveStrategy"
{
    /// <summary>
    /// Decides which work belongs in a wave, by narrowing and ordering the task record it is given. A
    /// strategy is a filter and a sort and nothing else: the caller finds and walks the records, so a
    /// strategy cannot accidentally consume the set it was asked to describe.
    /// </summary>
    /// <param name="Wave">The wave being filled.</param>
    /// <param name="WarehouseTask">The task record to filter and sort. Any existing filters are replaced.</param>
    /// <returns>True when there is at least one candidate.</returns>
    procedure SelectCandidates(var Wave: Record "WHA Wave"; var WarehouseTask: Record "WHA Warehouse Task"): Boolean;

    /// <summary>
    /// Describes in one line what this strategy picks, so the person filling a wave knows what they are
    /// about to get before they get it.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
