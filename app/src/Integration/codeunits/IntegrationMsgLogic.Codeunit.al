namespace WarehouseAdvanced.Integration;

codeunit 50650 "WHA Integration Msg. Logic" implements "WHA IIntegrationMessage"
{
    Access = Public;

    var
        UnhandledDeleteErr: Label 'Integration message %1 has not been dealt with yet, so it cannot be deleted. Cancel it first, so it is clear that it was deliberately dropped.', Comment = '%1 = the message entry number';

    /// <summary>
    /// Stamps a new message with the partner system, the time it arrived, and the status it starts in.
    /// </summary>
    /// <param name="IntegrationMessage">The message being inserted.</param>
    procedure Trigger_OnInsert(var IntegrationMessage: Record "WHA Integration Message")
    var
        Setup: Record "WHA Integration Setup";
    begin
        if IntegrationMessage."Received At" = 0DT then
            IntegrationMessage."Received At" := CurrentDateTime;

        if IntegrationMessage."Partner System" <> '' then
            exit;

        Setup.SetLoadFields("Partner System");
        if not Setup.Get() then
            exit;

        IntegrationMessage."Partner System" := Setup."Partner System";
    end;

    /// <summary>
    /// Refuses to delete a message that has not been dealt with, so nothing silently disappears from
    /// the inbox or the outbox.
    /// </summary>
    /// <param name="IntegrationMessage">The message being deleted.</param>
    procedure Trigger_OnDelete(var IntegrationMessage: Record "WHA Integration Message")
    begin
        if IntegrationMessage.Status = IntegrationMessage.Status::WHANew then
            Error(UnhandledDeleteErr, IntegrationMessage."Entry No.");
    end;
}
