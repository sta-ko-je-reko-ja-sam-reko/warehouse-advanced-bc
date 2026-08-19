namespace WarehouseAdvanced.Integration;

codeunit 50654 "WHA Int. Unhandled Message" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        NoHandlerErr: Label 'Nothing in this app knows how to apply a message of type %1. Either the partner system sent a type this version does not support, or the app that adds it is not installed.', Comment = '%1 = the message type that arrived';

    /// <summary>
    /// Rejects the message, because no handler is bound to its type. This is the default implementation,
    /// so a message type added by a dependent app that is not installed fails with a readable reason
    /// rather than being silently dropped.
    /// </summary>
    /// <param name="IntegrationMessage">The message that cannot be applied.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    begin
        Error(NoHandlerErr, IntegrationMessage."Message Type");
    end;

    /// <summary>
    /// Collects nothing. A type with no handler has nothing to send.
    /// </summary>
    procedure CollectOutbound()
    begin
    end;
}
