namespace WarehouseAdvanced.Packing;

interface "WHA IPackSession"
{
    /// <summary>
    /// Stamps a new packing session with who started it and when.
    /// </summary>
    /// <param name="PackSession">The session being inserted.</param>
    procedure Trigger_OnInsert(var PackSession: Record "WHA Pack Session");

    /// <summary>
    /// Refuses to delete a session that produced a carton somebody may have taped shut and shipped.
    /// </summary>
    /// <param name="PackSession">The session being deleted.</param>
    procedure Trigger_OnDelete(var PackSession: Record "WHA Pack Session");

    /// <summary>
    /// Opens a carton at a bench and starts packing into it.
    /// </summary>
    /// <param name="PackSession">Receives the new session.</param>
    /// <param name="StationCode">The bench being worked at.</param>
    procedure Start(var PackSession: Record "WHA Pack Session"; StationCode: Code[20]);

    /// <summary>
    /// Puts goods into the carton being packed.
    /// </summary>
    /// <param name="PackSession">The session being worked.</param>
    /// <param name="ItemNo">What is going in.</param>
    /// <param name="VariantCode">Which variant, if any.</param>
    /// <param name="Quantity">How much.</param>
    procedure PackItem(var PackSession: Record "WHA Pack Session"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal);

    /// <summary>
    /// Records that somebody has checked what is in the carton against what should be.
    /// </summary>
    /// <param name="PackSession">The session being verified.</param>
    procedure Verify(var PackSession: Record "WHA Pack Session");

    /// <summary>
    /// Closes the carton. Refuses an empty one, and refuses an unverified one when the setup asks for
    /// verification.
    /// </summary>
    /// <param name="PackSession">The session to close.</param>
    procedure Close(var PackSession: Record "WHA Pack Session");

    /// <summary>
    /// Abandons the packing. The carton stays as it is, holding whatever was already put in it.
    /// </summary>
    /// <param name="PackSession">The session to cancel.</param>
    procedure Cancel(var PackSession: Record "WHA Pack Session");
}
