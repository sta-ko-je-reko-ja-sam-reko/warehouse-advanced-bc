namespace WarehouseAdvanced.Counting;

interface "WHA ICountSelection"
{
    /// <summary>
    /// Decides what a sheet counts, by adding a line for each thing it finds at the sheet's location.
    /// Unlike a wave strategy, a selection builds rows rather than filtering them: the two selections
    /// that ship produce different shapes of line — one per item in a bin, one per handling unit line —
    /// so a filter and a sort cannot express the choice.
    /// </summary>
    /// <param name="CountSheet">The sheet being filled.</param>
    /// <returns>How many lines were added.</returns>
    procedure Fill(var CountSheet: Record "WHA Count Sheet"): Integer;

    /// <summary>
    /// Describes in one line what this selection gathers, so the person filling a sheet knows what they
    /// are about to send somebody to count.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
