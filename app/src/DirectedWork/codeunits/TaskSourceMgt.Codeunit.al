namespace WarehouseAdvanced.DirectedWork;

codeunit 50207 "WHA Task Source Mgt."
{
    Access = Public;

    /// <summary>
    /// Raises warehouse tasks for one standard warehouse document, through whichever implementation the
    /// source type names. This is the single place the rest of the app calls, so nothing outside the
    /// implementations learns what a warehouse receipt is.
    /// </summary>
    /// <param name="SourceType">The kind of document being read.</param>
    /// <param name="SourceNo">The document to read.</param>
    /// <returns>How many tasks were raised.</returns>
    procedure GenerateFrom(SourceType: Enum "WHA Task Source"; SourceNo: Code[20]): Integer
    var
        TaskSource: Interface "WHA ITaskSource";
    begin
        TaskSource := SourceType;
        exit(TaskSource.Generate(SourceNo));
    end;

    /// <summary>
    /// Describes in one line what a kind of source is and what it turns into.
    /// </summary>
    /// <param name="SourceType">The kind of document.</param>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(SourceType: Enum "WHA Task Source"): Text
    var
        TaskSource: Interface "WHA ITaskSource";
    begin
        TaskSource := SourceType;
        exit(TaskSource.Describe());
    end;

    /// <summary>
    /// Names the document a task came from, in a form fit to show a person.
    /// </summary>
    /// <param name="WarehouseTask">The task to describe the origin of.</param>
    /// <returns>The origin in the user's language, or an empty text when there is no document.</returns>
    procedure DescribeLink(var WarehouseTask: Record "WHA Warehouse Task"): Text
    var
        TaskSource: Interface "WHA ITaskSource";
    begin
        TaskSource := WarehouseTask."Source Type";
        exit(TaskSource.DescribeLink(WarehouseTask));
    end;

    /// <summary>
    /// Answers whether the line a task came from still has something outstanding on it.
    /// </summary>
    /// <param name="WarehouseTask">The task to check the origin of.</param>
    /// <returns>True while the source line still wants the work.</returns>
    procedure SourceIsOpen(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        TaskSource: Interface "WHA ITaskSource";
    begin
        TaskSource := WarehouseTask."Source Type";
        exit(TaskSource.SourceIsOpen(WarehouseTask));
    end;

    /// <summary>
    /// Opens the document a task came from.
    /// </summary>
    /// <param name="WarehouseTask">The task to show the origin of.</param>
    /// <returns>True when a document was opened.</returns>
    procedure ShowSource(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    var
        TaskSource: Interface "WHA ITaskSource";
    begin
        TaskSource := WarehouseTask."Source Type";
        exit(TaskSource.ShowSource(WarehouseTask));
    end;

    /// <summary>
    /// Answers whether a source line has already had work raised for it that nobody has cancelled. This
    /// is what makes raising work twice from the same document harmless: the second run adds only what
    /// the first one did not.
    /// </summary>
    /// <param name="SourceType">The kind of document.</param>
    /// <param name="SourceNo">The document.</param>
    /// <param name="SourceLineNo">The line on it.</param>
    /// <returns>True when a task that is not cancelled already covers the line.</returns>
    procedure HasOpenTask(SourceType: Enum "WHA Task Source"; SourceNo: Code[20]; SourceLineNo: Integer): Boolean
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetCurrentKey("Source Type", "Source No.", "Source Line No.");
        WarehouseTask.SetRange("Source Type", SourceType);
        WarehouseTask.SetRange("Source No.", SourceNo);
        WarehouseTask.SetRange("Source Line No.", SourceLineNo);
        WarehouseTask.SetFilter(Status, '<>%1', WarehouseTask.Status::WHACancelled);
        exit(not WarehouseTask.IsEmpty());
    end;

    /// <summary>
    /// Stamps where a task came from. Kept here rather than on each implementation so every source
    /// records the same four things in the same way.
    /// </summary>
    /// <param name="WarehouseTask">The task being built.</param>
    /// <param name="SourceType">The kind of document.</param>
    /// <param name="SourceNo">The warehouse document the work was read from.</param>
    /// <param name="SourceLineNo">The line on it.</param>
    /// <param name="SourceDocumentNo">The order the warehouse document is serving, when there is one.</param>
    procedure StampSource(var WarehouseTask: Record "WHA Warehouse Task"; SourceType: Enum "WHA Task Source"; SourceNo: Code[20]; SourceLineNo: Integer; SourceDocumentNo: Code[20])
    begin
        WarehouseTask."Source Type" := SourceType;
        WarehouseTask."Source No." := SourceNo;
        WarehouseTask."Source Line No." := SourceLineNo;
        WarehouseTask."Source Document No." := SourceDocumentNo;
    end;
}
