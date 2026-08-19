namespace WarehouseAdvanced.Core;

codeunit 50008 "WHA No Activity Cues" implements "WHA IActivityCues"
{
    Access = Public;

    /// <summary>
    /// Counts nothing. The foundation ships no activities of its own: a role centre tile is a statement
    /// about warehouse work, and the foundation does no warehouse work.
    /// </summary>
    /// <param name="Results">Left untouched.</param>
    procedure AddCounts(var Results: Dictionary of [Text, Text])
    begin
    end;
}
