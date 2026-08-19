namespace WarehouseAdvanced.LabourManagement;

interface "WHA ILabourStandard"
{
    /// <summary>
    /// Works out how long a piece of work should have taken. A basis reads a standard and a quantity and
    /// answers a number of minutes; it never looks at how long the work actually took, so it cannot be
    /// written to agree with the answer.
    /// </summary>
    /// <param name="LabourStandard">The standard that applies.</param>
    /// <param name="QuantityHandled">How much was actually moved.</param>
    /// <returns>The expected time in minutes.</returns>
    procedure ExpectedMinutes(var LabourStandard: Record "WHA Labour Standard"; QuantityHandled: Decimal): Decimal;

    /// <summary>
    /// Describes in one line how this basis works out expected time, so whoever writes a standard knows
    /// which of its numbers will be used.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
