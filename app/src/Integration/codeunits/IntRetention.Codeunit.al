namespace WarehouseAdvanced.Integration;

using System.DataAdministration;

codeunit 50661 "WHA Int. Retention"
{
    Access = Public;

    /// <summary>
    /// Offers the integration message log to the standard retention policy framework, so an administrator
    /// can say how long messages are kept and Business Central's own job does the deleting.
    /// </summary>
    /// <remarks>
    /// The message log is the only table in this app that grows without a business event to bound it: a
    /// partner that sends a thousand messages a day fills it a thousand rows a day, each carrying a
    /// payload blob, and nothing in the business process ever removes one. Writing a bespoke clean-up
    /// would have meant a setup field, a scheduler, a batch size and a log — all of which the platform
    /// already has, with a UI and an audit trail this feature would only imitate badly.
    /// </remarks>
    procedure RegisterAllowedTable()
    var
        IntegrationMessage: Record "WHA Integration Message";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RetenPolFiltering: Enum "Reten. Pol. Filtering";
        RetenPolDeleting: Enum "Reten. Pol. Deleting";
        TableFilters: JsonArray;
    begin
        BuildDefaultFilters(IntegrationMessage, TableFilters);
        RetenPolAllowedTables.AddAllowedTable(
            Database::"WHA Integration Message",
            IntegrationMessage.FieldNo("Processed At"),
            MinimumRetentionDays(),
            RetenPolFiltering::Default,
            RetenPolDeleting::Default,
            TableFilters);
    end;

    /// <summary>
    /// Answers the fewest days a message may be kept for. A retention policy cannot be set shorter than
    /// this, so nobody can configure the log away faster than the people who read it work.
    /// </summary>
    /// <returns>The mandatory minimum retention in days.</returns>
    procedure MinimumRetentionDays(): Integer
    begin
        exit(7);
    end;

    local procedure BuildDefaultFilters(var IntegrationMessage: Record "WHA Integration Message"; var TableFilters: JsonArray)
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        MessageRecordRef: RecordRef;
        RetentionPeriodEnum: Enum "Retention Period Enum";
    begin
        IntegrationMessage.Reset();
        IntegrationMessage.SetRange(Status, IntegrationMessage.Status::WHAProcessed);
        MessageRecordRef.GetTable(IntegrationMessage);

        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriodEnum::"1 Month", IntegrationMessage.FieldNo("Processed At"), true, false, MessageRecordRef);
    end;
}
