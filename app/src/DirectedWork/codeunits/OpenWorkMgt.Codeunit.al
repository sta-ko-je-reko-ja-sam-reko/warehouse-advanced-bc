namespace WarehouseAdvanced.DirectedWork;

codeunit 50213 "WHA Open Work Mgt."
{
    Access = Public;

    /// <summary>
    /// Hands a document about to be posted to whatever the warehouse task setup says should happen when
    /// jobs raised from it are still open. This is the single place the subscribers call, so neither of
    /// them learns what any policy does.
    /// </summary>
    /// <param name="SourceType">The kind of document being posted.</param>
    /// <param name="SourceNo">The document being posted.</param>
    internal procedure Check(SourceType: Enum "WHA Task Source"; SourceNo: Code[20])
    var
        Setup: Record "WHA Warehouse Task Setup";
        OpenWorkPolicy: Interface "WHA IOpenWorkPolicy";
    begin
        Setup.SetLoadFields("WHA Enabled", "Open Work On Posting");
        if not Setup.Get() then
            exit;
        if not Setup."WHA Enabled" then
            exit;

        OpenWorkPolicy := Setup."Open Work On Posting";
        OpenWorkPolicy.Check(SourceType, SourceNo);
    end;

    /// <summary>
    /// Describes in one line what the chosen policy does.
    /// </summary>
    /// <param name="Policy">The policy chosen in the warehouse task setup.</param>
    /// <returns>A short description in the user's language.</returns>
    internal procedure Describe(Policy: Enum "WHA Open Work Policy"): Text
    var
        OpenWorkPolicy: Interface "WHA IOpenWorkPolicy";
    begin
        OpenWorkPolicy := Policy;
        exit(OpenWorkPolicy.Describe());
    end;
}
