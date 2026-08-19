namespace WarehouseAdvanced.MobileDevice;

using WarehouseAdvanced.DirectedWork;

interface "WHA IRFFlow"
{
    /// <summary>
    /// Establishes which device the operator is working on, and refuses one that is unknown or blocked.
    /// </summary>
    /// <param name="DeviceCode">The code scanned or typed on the handheld.</param>
    /// <param name="RFDevice">Receives the device. Left blank when unregistered devices are allowed.</param>
    procedure SignIn(DeviceCode: Code[20]; var RFDevice: Record "WHA RF Device");

    /// <summary>
    /// Hands the operator the work they should do next, at the location the device belongs to.
    /// </summary>
    /// <param name="RFDevice">The device the operator is working on.</param>
    /// <param name="WarehouseTask">Receives the task to work.</param>
    /// <returns>True when there is work to do.</returns>
    procedure NextTask(var RFDevice: Record "WHA RF Device"; var WarehouseTask: Record "WHA Warehouse Task"): Boolean;

    /// <summary>
    /// Decides where a task starts on the handheld, which depends on what the task actually names.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <returns>The step to show first.</returns>
    procedure FirstStep(var WarehouseTask: Record "WHA Warehouse Task"): Enum "WHA RF Step";

    /// <summary>
    /// Checks what the operator scanned against what the current step asked for, and answers with the
    /// step that follows. Raise an error to reject the scan.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <param name="CurrentStep">The step the operator is on.</param>
    /// <param name="ScannedValue">What came off the scanner.</param>
    /// <returns>The next step.</returns>
    procedure Scan(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"; ScannedValue: Text): Enum "WHA RF Step";

    /// <summary>
    /// The line of text the operator reads. It is the whole user interface of a handheld, so it says
    /// exactly one thing to do next.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <param name="CurrentStep">The step the operator is on.</param>
    /// <returns>What to do next, in the operator's language.</returns>
    procedure Instruction(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"): Text;

    /// <summary>
    /// Finishes the task the operator is holding and returns them to asking for work.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <param name="CurrentStep">The step the operator is on.</param>
    /// <returns>The step to show next.</returns>
    procedure Confirm(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"): Enum "WHA RF Step";

    /// <summary>
    /// Gives the task back to the queue, for when the operator cannot finish it.
    /// </summary>
    /// <param name="WarehouseTask">The task being worked.</param>
    /// <returns>The step to show next.</returns>
    procedure HandBack(var WarehouseTask: Record "WHA Warehouse Task"): Enum "WHA RF Step";
}
