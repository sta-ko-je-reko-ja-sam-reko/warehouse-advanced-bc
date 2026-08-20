namespace WarehouseAdvanced.DirectedWork;

codeunit 50214 "WHA Any User Works" implements "WHA IWhseAccessPolicy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Anybody who can reach the warehouse tasks can be given one. Business Central''s own warehouse employee list is not consulted, so a person can hold work at a location its own warehouse pages would not let them into.';

    /// <summary>
    /// Lets everybody through. This is what the app did before it could see the warehouse employee list
    /// at all, kept as a choice rather than a missing feature: a warehouse that runs this app and nothing
    /// else of Business Central's warehouse has no employee list to consult.
    /// </summary>
    /// <param name="UserIdToCheck">The person the work is being given to. Ignored.</param>
    /// <param name="LocationCode">Where the work happens. Ignored.</param>
    procedure Check(UserIdToCheck: Code[50]; LocationCode: Code[10])
    begin
    end;

    /// <summary>
    /// Describes in one line who this policy lets work.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
