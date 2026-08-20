namespace WarehouseAdvanced.Registration;

codeunit 50800 "WHA No Whse. Registration" implements "WHA IWhseRegistration"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Nothing is recorded. The app moves the goods in its own records, and what Business Central believes is in each bin is left where it was for somebody to correct by hand.';

    /// <summary>
    /// Records nothing. This is what the app did before it could register a move at all, kept as a
    /// choice rather than a missing feature: a warehouse whose bins are not maintained in Business
    /// Central has nothing for a warehouse entry to be true about.
    /// </summary>
    /// <param name="MoveRequest">The moves to record. Left untouched.</param>
    /// <returns>Zero.</returns>
    procedure Register(var MoveRequest: Record "WHA Whse. Move Request"): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Describes in one line what this way of recording a move does.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Answers whether this way of recording a move changes what Business Central believes is in each bin.
    /// </summary>
    /// <returns>False.</returns>
    procedure UpdatesBinContent(): Boolean
    begin
        exit(false);
    end;
}
