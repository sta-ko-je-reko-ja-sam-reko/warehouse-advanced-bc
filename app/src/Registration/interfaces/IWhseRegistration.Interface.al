namespace WarehouseAdvanced.Registration;

interface "WHA IWhseRegistration"
{
    /// <summary>
    /// Takes every move on the request and tells Business Central about it, in whatever way this
    /// implementation tells it. The request is a buffer the caller owns, so an implementation that
    /// records nothing is a complete implementation.
    /// </summary>
    /// <param name="MoveRequest">The moves to record. Marked up in place with what happened to each.</param>
    /// <returns>How many moves the implementation recorded.</returns>
    procedure Register(var MoveRequest: Record "WHA Whse. Move Request"): Integer;

    /// <summary>
    /// Describes in one line what this way of recording a move does, so whoever chooses it in setup can
    /// see what they are agreeing to before the floor starts moving stock.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;

    /// <summary>
    /// Answers whether this way of recording a move changes what Business Central believes is in each
    /// bin. A warehouse where the answer is no is a warehouse where the app and Business Central hold
    /// two different pictures of the same shelf.
    /// </summary>
    /// <returns>True when running this implementation writes warehouse entries and maintains bin content.</returns>
    procedure UpdatesBinContent(): Boolean;
}
