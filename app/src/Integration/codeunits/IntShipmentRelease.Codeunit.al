namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.DirectedWork;

codeunit 50665 "WHA Int. Shipment Release" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        NoDocumentErr: Label 'Message %1 does not say which warehouse shipment to release. The shipment number belongs in the external ID.', Comment = '%1 = the message entry number';
        DuplicateErr: Label 'Warehouse shipment %1 has already been released by an earlier message. Releasing it twice would raise the same work again.', Comment = '%1 = the warehouse shipment number';
        NothingRaisedErr: Label 'Warehouse shipment %1 has nothing left to pick, so the release raised no work.', Comment = '%1 = the warehouse shipment number';

    /// <summary>
    /// Raises pick work for one standard warehouse shipment, as if somebody had pressed the action on the
    /// shipment itself. The shipment is named by the message's external ID rather than by its body, so a
    /// partner system that resends is refused rather than obeyed twice.
    /// </summary>
    /// <param name="IntegrationMessage">The release to apply.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    var
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        Raised: Integer;
    begin
        if IntegrationMessage."External Id" = '' then
            Error(NoDocumentErr, IntegrationMessage."Entry No.");

        if MessageMgt.HasProcessedInbound(IntegrationMessage."Message Type", IntegrationMessage."External Id", IntegrationMessage."Entry No.") then
            Error(DuplicateErr, IntegrationMessage."External Id");

        Raised := TaskSourceMgt.GenerateFrom(SourceType::WHAWhseShipment, CopyStr(IntegrationMessage."External Id", 1, 20));
        if Raised = 0 then
            Error(NothingRaisedErr, IntegrationMessage."External Id");
    end;

    /// <summary>
    /// Collects nothing. A release is an instruction this app receives, never one it issues.
    /// </summary>
    procedure CollectOutbound()
    begin
    end;
}
