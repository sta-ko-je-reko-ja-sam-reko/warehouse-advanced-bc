namespace WarehouseAdvanced.Core;

codeunit 50009 "WHA Activities Cue Calc"
{
    Access = Internal;

    /// <summary>
    /// Asks every feature that has registered activities for its counts, and hands them back to the role
    /// centre. Runs in a read-only background session, so the home page opens without waiting for a
    /// single count.
    /// </summary>
    /// <remarks>
    /// The foundation does not know which features have tiles. It walks the values of an extensible enum
    /// and asks each one, exactly as the guided setup walks `WHA Feature` — so a feature that adds a tile
    /// adds an enum value and a codeunit, and nothing here changes.
    /// </remarks>
    trigger OnRun()
    var
        ActivityCues: Interface "WHA IActivityCues";
        Results: Dictionary of [Text, Text];
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"WHA Activity Provider".Ordinals() do begin
            ActivityCues := Enum::"WHA Activity Provider".FromInteger(Ordinal);
            ActivityCues.AddCounts(Results);
        end;

        Page.SetBackgroundTaskResult(Results);
    end;
}
