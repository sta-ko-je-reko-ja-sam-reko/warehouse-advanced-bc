namespace WarehouseAdvanced.Posting;

interface "WHA IInvtPosting"
{
    /// <summary>
    /// Takes everything on the request and does with it whatever this way of posting does. The request is
    /// a buffer the caller owns, so an implementation that writes nothing is a complete implementation.
    /// </summary>
    /// <param name="PostingRequest">The lines to post. Marked up in place with what happened to each.</param>
    /// <returns>How many lines the implementation took.</returns>
    procedure Post(var PostingRequest: Record "WHA Posting Request"): Integer;

    /// <summary>
    /// Describes in one line what this way of posting does, so whoever chooses it in setup can see what
    /// they are agreeing to before stock starts moving.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;

    /// <summary>
    /// Answers whether this way of posting writes to the item ledger. What is recorded against the count
    /// sheet or the hold depends on the answer: a journal line waiting for somebody is not a posting.
    /// </summary>
    /// <returns>True when running this implementation changes what Business Central believes is in stock.</returns>
    procedure WritesToLedger(): Boolean;
}
