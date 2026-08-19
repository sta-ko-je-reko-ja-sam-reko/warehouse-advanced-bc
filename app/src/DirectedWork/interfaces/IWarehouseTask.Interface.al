namespace WarehouseAdvanced.DirectedWork;

interface "WHA IWarehouseTask"
{
    /// <summary>
    /// Assigns the number series value, the default priority, and releases the task when the setup asks
    /// for tasks to be released automatically.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being inserted.</param>
    procedure Trigger_OnInsert(var WarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Refuses the delete when the task is being worked or has been completed, so the record of the work
    /// survives.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being deleted.</param>
    procedure Trigger_OnDelete(var WarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Clears both bins when the location changes, so a bin from the previous location cannot be kept.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_LocationCode(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Copies the location and bin of the handling unit onto the task, and refuses a unit that has
    /// already shipped.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_HandlingUnitNo(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Clears the variant and unit of measure when the item changes, then copies the base unit of
    /// measure from the item.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_ItemNo(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Rejects a negative quantity.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_Quantity(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Rejects a negative priority.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_Priority(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Moves the task between people. Refuses handing started work straight to someone else, and
    /// enforces the limit on how many tasks one person may hold. Clearing the user returns the task to
    /// the queue — including work that had been started, which is how an operator abandons a job.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task being validated.</param>
    /// <param name="xWarehouseTask">The warehouse task as it was before the change.</param>
    procedure Validate_AssignedToUserID(var WarehouseTask: Record "WHA Warehouse Task"; xWarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Makes the task available to the floor. Refuses a task that does not yet say where the work is or
    /// what is being moved.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to release.</param>
    procedure Release(var WarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Gives a released task to a person and records when it happened.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to assign.</param>
    /// <param name="AssignToUserId">The user the task is assigned to.</param>
    procedure Assign(var WarehouseTask: Record "WHA Warehouse Task"; AssignToUserId: Code[50]);

    /// <summary>
    /// Marks an assigned task as being worked and records when it started.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to start.</param>
    procedure Start(var WarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Marks a task as done, records when it finished, and moves the handling unit it carried to the
    /// destination the task names.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to complete.</param>
    procedure Complete(var WarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Finishes a task with less than it asked for, recording how much was moved and why the rest was
    /// not. Raises a follow-up task for the remainder when the setup asks for one.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to complete short.</param>
    /// <param name="HandledQuantity">How much was actually moved. Zero when nothing could be.</param>
    /// <param name="Reason">Why the rest was not moved.</param>
    procedure CompleteShort(var WarehouseTask: Record "WHA Warehouse Task"; HandledQuantity: Decimal; Reason: Enum "WHA Whse. Short Reason");

    /// <summary>
    /// Withdraws a task that is no longer needed, keeping it as a record of what was asked for.
    /// </summary>
    /// <param name="WarehouseTask">The warehouse task to cancel.</param>
    procedure Cancel(var WarehouseTask: Record "WHA Warehouse Task");

    /// <summary>
    /// Answers what a person should work on next: their own unfinished work first, then the most urgent
    /// released task at the location, which is assigned to them as it is handed over.
    /// </summary>
    /// <param name="ForUserId">The person asking for work.</param>
    /// <param name="LocationCode">The location to look in. Blank looks everywhere.</param>
    /// <param name="WarehouseTask">Receives the task the person should work on.</param>
    /// <returns>True when there is work to do.</returns>
    procedure GetNextForUser(ForUserId: Code[50]; LocationCode: Code[10]; var WarehouseTask: Record "WHA Warehouse Task"): Boolean;
}
