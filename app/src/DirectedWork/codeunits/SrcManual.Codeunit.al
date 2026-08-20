namespace WarehouseAdvanced.DirectedWork;

codeunit 50204 "WHA Src Manual" implements "WHA ITaskSource"
{
    Access = Public;

    var
        DescriptionLbl: Label 'The task was put on the queue by somebody, not raised from a document. Nothing outside the app is waiting on it and nothing outside the app will close it.';

    /// <summary>
    /// Raises nothing. A task created by hand has no document behind it to read.
    /// </summary>
    /// <param name="SourceNo">Ignored.</param>
    /// <returns>Zero.</returns>
    procedure Generate(SourceNo: Code[20]): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Describes in one line what this kind of source is.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Names the document the task came from. There is none.
    /// </summary>
    /// <param name="WarehouseTask">Ignored.</param>
    /// <returns>An empty text.</returns>
    procedure DescribeLink(var WarehouseTask: Record "WHA Warehouse Task"): Text
    begin
        exit('');
    end;

    /// <summary>
    /// Writes nothing. Work somebody raised by hand answers to no document.
    /// </summary>
    /// <param name="WarehouseTask">The finished task, unused.</param>
    /// <returns>Always false.</returns>
    procedure WriteBack(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    begin
        exit(false);
    end;

    /// <summary>
    /// Answers whether the source still wants the work. A task with no source is nobody's to close but
    /// the warehouse's, so it is always its own answer.
    /// </summary>
    /// <param name="WarehouseTask">Ignored.</param>
    /// <returns>True.</returns>
    procedure SourceIsOpen(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// Opens the document the task came from. There is none, so nothing is opened.
    /// </summary>
    /// <param name="WarehouseTask">Ignored.</param>
    /// <returns>False.</returns>
    procedure ShowSource(var WarehouseTask: Record "WHA Warehouse Task"): Boolean
    begin
        exit(false);
    end;
}
