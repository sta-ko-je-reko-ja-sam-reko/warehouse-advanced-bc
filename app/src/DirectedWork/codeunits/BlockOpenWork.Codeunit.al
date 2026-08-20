namespace WarehouseAdvanced.DirectedWork;

codeunit 50211 "WHA Block Open Work" implements "WHA IOpenWorkPolicy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'A receipt or shipment cannot be posted while jobs raised from it are still open. Posting stops with a message naming the document and how many jobs are outstanding.';
        OpenWorkErr: Label 'Document %1 still has %2 warehouse job(s) that nobody has finished or cancelled, so what it is about to post is not what the floor has done. Finish or cancel them first.', Comment = '%1 = the warehouse document number; %2 = how many jobs are still open';

    /// <summary>
    /// Stops the posting when the document still has work nobody has finished. A cancelled job does not
    /// count: somebody decided it was not needed, and that is an answer.
    /// </summary>
    /// <param name="SourceType">The kind of document being posted.</param>
    /// <param name="SourceNo">The document being posted.</param>
    procedure Check(SourceType: Enum "WHA Task Source"; SourceNo: Code[20])
    var
        WarehouseTask: Record "WHA Warehouse Task";
        OpenTasks: Integer;
    begin
        if SourceNo = '' then
            exit;

        WarehouseTask.SetCurrentKey("Source Type", "Source No.", "Source Line No.");
        WarehouseTask.SetRange("Source Type", SourceType);
        WarehouseTask.SetRange("Source No.", SourceNo);
        WarehouseTask.SetFilter(Status, '<>%1&<>%2', WarehouseTask.Status::WHACancelled, WarehouseTask.Status::WHACompleted);
        OpenTasks := WarehouseTask.Count();
        if OpenTasks = 0 then
            exit;

        Error(OpenWorkErr, SourceNo, OpenTasks);
    end;

    /// <summary>
    /// Describes in one line what this policy does.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
