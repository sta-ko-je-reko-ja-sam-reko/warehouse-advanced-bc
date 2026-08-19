namespace WarehouseAdvanced.Integration;

codeunit 50660 "WHA Int. Message Runner"
{
    Access = Internal;
    TableNo = "WHA Integration Message";

    /// <summary>
    /// Applies one inbound message through the handler its type is bound to. Runs as its own unit of
    /// work so that a message which fails halfway leaves nothing behind.
    /// </summary>
    trigger OnRun()
    var
        Handler: Interface "WHA IIntMessageHandler";
    begin
        Handler := Rec."Message Type";
        Handler.HandleInbound(Rec);
    end;
}
