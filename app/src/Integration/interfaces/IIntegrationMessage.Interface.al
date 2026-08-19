namespace WarehouseAdvanced.Integration;

interface "WHA IIntegrationMessage"
{
    /// <summary>
    /// Stamps a new message with the partner system, the time it arrived, and the status it starts in.
    /// </summary>
    /// <param name="IntegrationMessage">The message being inserted.</param>
    procedure Trigger_OnInsert(var IntegrationMessage: Record "WHA Integration Message");

    /// <summary>
    /// Refuses to delete a message that has not been dealt with, so nothing silently disappears from
    /// the inbox or the outbox.
    /// </summary>
    /// <param name="IntegrationMessage">The message being deleted.</param>
    procedure Trigger_OnDelete(var IntegrationMessage: Record "WHA Integration Message");
}
