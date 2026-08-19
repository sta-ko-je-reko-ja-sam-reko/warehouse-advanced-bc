namespace WarehouseAdvanced.Labelling;

interface "WHA ILabelCodeFormat"
{
    /// <summary>
    /// Builds the code for one serial reference. This is a pure calculation: the same reference always
    /// gives the same code, and building one uses nothing up. Handing out references is the facade's
    /// job, which is what lets a setup page show an example without spending a number.
    /// </summary>
    /// <param name="SerialReference">The number the code is built around.</param>
    /// <returns>The code.</returns>
    procedure Build(SerialReference: BigInteger): Code[20];

    /// <summary>
    /// Determines whether a code could have been produced by this format. Used to check codes that
    /// arrive from outside, where a typo and a real code look alike.
    /// </summary>
    /// <param name="CodeValue">The code to check.</param>
    /// <returns>True when the code is well formed for this format.</returns>
    procedure IsValid(CodeValue: Code[20]): Boolean;

    /// <summary>
    /// Describes the format in one line, so the person choosing it knows what their labels will carry.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text;
}
