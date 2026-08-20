namespace WarehouseAdvanced.DirectedWork;

interface "WHA IWhseAccessPolicy"
{
    /// <summary>
    /// Decides whether a person may be given warehouse work at a location. An implementation that lets
    /// everybody through is a complete implementation.
    /// </summary>
    /// <param name="UserIdToCheck">The person the work is being given to.</param>
    /// <param name="LocationCode">Where the work happens. Blank when the job does not say yet.</param>
    procedure Check(UserIdToCheck: Code[50]; LocationCode: Code[10]);

    /// <summary>
    /// Describes in one line who this policy lets work, so whoever chooses it in setup can see what
    /// they are agreeing to.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
