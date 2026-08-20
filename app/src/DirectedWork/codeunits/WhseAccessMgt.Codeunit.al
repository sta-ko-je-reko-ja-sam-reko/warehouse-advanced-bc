namespace WarehouseAdvanced.DirectedWork;

codeunit 50216 "WHA Whse. Access Mgt."
{
    Access = Public;

    /// <summary>
    /// Hands a person and a location to whatever the warehouse task setup says about who may be given
    /// work. This is the single place the task calls, so it never learns what any policy does.
    /// </summary>
    /// <param name="UserIdToCheck">The person the work is being given to.</param>
    /// <param name="LocationCode">Where the work happens. Blank when the job does not say yet.</param>
    internal procedure Check(UserIdToCheck: Code[50]; LocationCode: Code[10])
    var
        Setup: Record "WHA Warehouse Task Setup";
        WhseAccessPolicy: Interface "WHA IWhseAccessPolicy";
    begin
        Setup.SetLoadFields("Who May Be Given Work");
        if not Setup.Get() then
            exit;

        WhseAccessPolicy := Setup."Who May Be Given Work";
        WhseAccessPolicy.Check(UserIdToCheck, LocationCode);
    end;

    /// <summary>
    /// Describes in one line who the chosen policy lets work.
    /// </summary>
    /// <param name="Policy">The policy chosen in the warehouse task setup.</param>
    /// <returns>A short description in the user's language.</returns>
    internal procedure Describe(Policy: Enum "WHA Whse. Access Policy"): Text
    var
        WhseAccessPolicy: Interface "WHA IWhseAccessPolicy";
    begin
        WhseAccessPolicy := Policy;
        exit(WhseAccessPolicy.Describe());
    end;
}
