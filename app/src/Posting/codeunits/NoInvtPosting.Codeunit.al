namespace WarehouseAdvanced.Posting;

codeunit 50750 "WHA No Invt. Posting" implements "WHA IInvtPosting"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Nothing is posted. The app records what was found, and what Business Central believes is in stock is left alone for somebody to correct by hand.';

    /// <summary>
    /// Takes nothing. This is what the app did before it could post at all, kept as a choice rather than
    /// a missing feature: a warehouse that will not let a system write to its ledger unattended can run
    /// the whole process and still own the correction.
    /// </summary>
    /// <param name="PostingRequest">The lines to post. Left untouched.</param>
    /// <returns>Zero.</returns>
    procedure Post(var PostingRequest: Record "WHA Posting Request"): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Describes in one line what this way of posting does.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Answers whether this way of posting writes to the item ledger.
    /// </summary>
    /// <returns>False.</returns>
    procedure WritesToLedger(): Boolean
    begin
        exit(false);
    end;
}
