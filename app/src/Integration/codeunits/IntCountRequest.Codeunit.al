namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Counting;

codeunit 50667 "WHA Int. Count Request" implements "WHA IIntMessageHandler"
{
    Access = Public;

    var
        NoLocationErr: Label 'Message %1 does not say where to count. The location code belongs in the external ID.', Comment = '%1 = the message entry number';
        DuplicateErr: Label 'A count has already been raised for external ID %1. The partner system should send a new identifier to ask for another one.', Comment = '%1 = the external identifier the partner system sent';
        CountingOffErr: Label 'Counting is switched off in this company, so a count cannot be raised. Turn the counting feature on before the partner system asks for one.';
        SheetDescriptionLbl: Label 'Requested by %1', Comment = '%1 = the partner system that asked for the count';

    /// <summary>
    /// Raises a count sheet for the location the message names, and puts on it whatever the counting
    /// setup's own selection finds there. The sheet is left open: this creates the work, it does not
    /// perform it, and nothing about the count is decided here that a person could not decide on the
    /// sheet afterwards.
    /// </summary>
    /// <param name="IntegrationMessage">The request to apply.</param>
    procedure HandleInbound(var IntegrationMessage: Record "WHA Integration Message")
    var
        CountSetup: Record "WHA Count Setup";
        CountSheet: Record "WHA Count Sheet";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";
    begin
        if IntegrationMessage."External Id" = '' then
            Error(NoLocationErr, IntegrationMessage."Entry No.");

        if MessageMgt.HasProcessedInbound(IntegrationMessage."Message Type", IntegrationMessage."External Id", IntegrationMessage."Entry No.") then
            Error(DuplicateErr, IntegrationMessage."External Id");

        CountSetup.SetLoadFields("WHA Enabled");
        if not CountSetup.Get() then
            Error(CountingOffErr);
        if not CountSetup."WHA Enabled" then
            Error(CountingOffErr);

        CountSheet.Init();
        CountSheet.Validate(Description, CopyStr(StrSubstNo(SheetDescriptionLbl, IntegrationMessage."Partner System"), 1, MaxStrLen(CountSheet.Description)));
        CountSheet.Validate("Location Code", CopyStr(IntegrationMessage."External Id", 1, MaxStrLen(CountSheet."Location Code")));
        CountSheet.Validate("Due Date", WorkDate());
        CountSheet.Insert(true);

        CountSheetLogic.Fill(CountSheet);

        IntegrationMessage."Record ID" := CountSheet.RecordId();
        IntegrationMessage.Modify(true);
    end;

    /// <summary>
    /// Collects nothing. Asking for a count is something the partner system does; what the count found
    /// goes back through its own message type.
    /// </summary>
    procedure CollectOutbound()
    begin
    end;
}
