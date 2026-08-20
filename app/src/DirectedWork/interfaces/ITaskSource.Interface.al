namespace WarehouseAdvanced.DirectedWork;

interface "WHA ITaskSource"
{
    /// <summary>
    /// Raises warehouse tasks for everything still outstanding on one standard warehouse document. What
    /// counts as outstanding, and what kind of work each line becomes, is the implementation's business —
    /// which is the whole point of the seam, because no two warehouses agree on it.
    /// </summary>
    /// <param name="SourceNo">The warehouse document to read.</param>
    /// <returns>How many tasks were raised. Zero is a valid answer and is not an error.</returns>
    procedure Generate(SourceNo: Code[20]): Integer;

    /// <summary>
    /// Describes in one line what this kind of source is and what it turns into, so whoever is about to
    /// raise work from it can see what they are asking for.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;

    /// <summary>
    /// Names the document a task came from, in a form fit to show a person.
    /// </summary>
    /// <param name="WarehouseTask">The task to describe the origin of.</param>
    /// <returns>The origin in the user's language, or an empty text when the task was not raised from a document.</returns>
    procedure DescribeLink(var WarehouseTask: Record "WHA Warehouse Task"): Text;

    /// <summary>
    /// Answers whether the line a task came from still has something outstanding on it. A task whose
    /// source has been received or shipped by some other route is work nobody needs doing, and this is
    /// what lets that be noticed rather than walked.
    /// </summary>
    /// <param name="WarehouseTask">The task to check the origin of.</param>
    /// <returns>True while the source line still wants the work.</returns>
    procedure SourceIsOpen(var WarehouseTask: Record "WHA Warehouse Task"): Boolean;

    /// <summary>
    /// Writes what the work actually did back onto the document line it came from. This is the point at
    /// which the app stops being an overlay on Business Central and starts driving it, so it is asked
    /// for rather than assumed: the caller decides whether to call this at all.
    ///
    /// What "writing back" means is the implementation's business, and it differs by document. It adds
    /// to what the line already has rather than replacing it, because two jobs can serve one line and
    /// the second must not undo the first.
    /// </summary>
    /// <param name="WarehouseTask">The finished task to write back.</param>
    /// <returns>True when a document line was changed.</returns>
    procedure WriteBack(var WarehouseTask: Record "WHA Warehouse Task"): Boolean;

    /// <summary>
    /// Opens the document a task came from, so somebody looking at a job on the queue can see what is
    /// waiting on it. The one place in this interface that touches the screen, and it is here rather
    /// than on the page because only the implementation knows which document to open.
    /// </summary>
    /// <param name="WarehouseTask">The task to show the origin of.</param>
    /// <returns>True when a document was opened.</returns>
    procedure ShowSource(var WarehouseTask: Record "WHA Warehouse Task"): Boolean;
}
