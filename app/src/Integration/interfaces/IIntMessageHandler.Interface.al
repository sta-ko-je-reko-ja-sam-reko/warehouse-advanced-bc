namespace WarehouseAdvanced.Integration;

interface "WHA IIntMessageHandler"
{
    /// <summary>
    /// Applies one inbound message to the app's own data. Raise an error to reject the message — the
    /// caller records the error text on the message and rolls back whatever this did.
    /// </summary>
    /// <param name="IntegrationMessage">The message to apply. Set its record ID to whatever was created or changed.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message");

    /// <summary>
    /// Adds an outbound message for everything of this type that the partner system has not been told
    /// about yet. Called for every message type by the outbound sweep, so a type with nothing to send
    /// does nothing.
    /// </summary>
    procedure CollectOutbound();
}
