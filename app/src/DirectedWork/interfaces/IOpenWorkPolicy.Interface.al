namespace WarehouseAdvanced.DirectedWork;

interface "WHA IOpenWorkPolicy"
{
    /// <summary>
    /// Decides what happens when a warehouse document is about to be posted while jobs raised from it
    /// are still open. An implementation that does nothing is a complete implementation.
    /// </summary>
    /// <param name="SourceType">The kind of document being posted.</param>
    /// <param name="SourceNo">The document being posted.</param>
    procedure Check(SourceType: Enum "WHA Task Source"; SourceNo: Code[20]);

    /// <summary>
    /// Describes in one line what this policy does, so whoever chooses it in setup can see what they
    /// are agreeing to.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
