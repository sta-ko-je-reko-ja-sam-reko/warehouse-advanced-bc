namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.DirectedWork;

interface "WHA IWave"
{
    /// <summary>
    /// Assigns the number from the foundation series and the defaults a new wave needs.
    /// </summary>
    /// <param name="Wave">The wave being inserted.</param>
    procedure Trigger_OnInsert(var Wave: Record "WHA Wave");

    /// <summary>
    /// Refuses to delete a wave that has reached the floor, and releases the work held by one that has
    /// not, so no task is left pointing at a wave that no longer exists.
    /// </summary>
    /// <param name="Wave">The wave being deleted.</param>
    procedure Trigger_OnDelete(var Wave: Record "WHA Wave");

    /// <summary>
    /// Fills an open wave with the work its strategy picks, up to the number of tasks it allows.
    /// </summary>
    /// <param name="Wave">The wave to fill.</param>
    /// <returns>How many tasks were added.</returns>
    procedure Fill(var Wave: Record "WHA Wave"): Integer;

    /// <summary>
    /// Works out how long the work already in a wave should take, from the labour standards. A wave is a
    /// promise that a shift can finish something, and a count of jobs is a poor proxy for that promise —
    /// twenty pallet moves and twenty piece picks are not the same afternoon.
    /// </summary>
    /// <param name="Wave">The wave to measure.</param>
    /// <param name="Measured">Receives whether any standard applied at all. False means the answer is zero because nobody has written standards, not because there is no work.</param>
    /// <returns>The expected time in minutes.</returns>
    procedure EstimateMinutes(var Wave: Record "WHA Wave"; var Measured: Boolean): Decimal;

    /// <summary>
    /// Puts one task into a wave.
    /// </summary>
    /// <param name="Wave">The wave to add to.</param>
    /// <param name="WarehouseTask">The task to add.</param>
    procedure AddTask(var Wave: Record "WHA Wave"; var WarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Takes one task back out of a wave, leaving the task itself alone.
    /// </summary>
    /// <param name="Wave">The wave to take from.</param>
    /// <param name="WarehouseTask">The task to remove.</param>
    procedure RemoveTask(var Wave: Record "WHA Wave"; var WarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Sends every job in the wave to the floor at once. That is what a wave is for: the work becomes
    /// available together rather than trickling out.
    /// </summary>
    /// <param name="Wave">The wave to release.</param>
    procedure Release(var Wave: Record "WHA Wave");

    /// <summary>
    /// Closes a wave whose work is all finished or withdrawn, and refuses one that still has work
    /// outstanding.
    /// </summary>
    /// <param name="Wave">The wave to complete.</param>
    procedure Complete(var Wave: Record "WHA Wave");

    /// <summary>
    /// Closes a wave that is finished, and does nothing to one that is not. Safe to call on anything.
    /// </summary>
    /// <param name="Wave">The wave to look at.</param>
    /// <returns>True when the wave was closed by this call.</returns>
    procedure CompleteIfFinished(var Wave: Record "WHA Wave"): Boolean;

    /// <summary>
    /// Withdraws a wave, cancelling any of its work that has not been started.
    /// </summary>
    /// <param name="Wave">The wave to cancel.</param>
    procedure Cancel(var Wave: Record "WHA Wave");
}
