namespace WarehouseAdvanced.Labelling;

using WarehouseAdvanced.HandlingUnit;

codeunit 50604 "WHA Label Mgt."
{
    Access = Public;

    var
        AlreadyLabelledErr: Label 'Handling unit %1 already carries the code %2. Printing a second code for the same unit is how two pallets end up wearing the same label.', Comment = '%1 = the handling unit number, %2 = the code it already has';
        ShippedUnitErr: Label 'Handling unit %1 has already been shipped, so there is no point labelling it now.', Comment = '%1 = the handling unit number';

    /// <summary>
    /// Takes the next label code in the configured format, using up a serial reference.
    /// </summary>
    /// <returns>The new code.</returns>
    procedure NextCode(): Code[20]
    var
        CodeFormat: Interface "WHA ILabelCodeFormat";
    begin
        CodeFormat := ConfiguredFormat();
        exit(CodeFormat.Build(NextSerialReference()));
    end;

    /// <summary>
    /// Works out what the next code would look like without using it up, so a setup page can show an
    /// example and a person can see whether the prefix they typed produces what they expected.
    /// </summary>
    /// <returns>The code that the next serial reference would produce.</returns>
    procedure ExampleCode(): Code[20]
    var
        Setup: Record "WHA Label Setup";
        LabelFeatureSetup: Codeunit "WHA Label Feature Setup";
        CodeFormat: Interface "WHA ILabelCodeFormat";
    begin
        LabelFeatureSetup.EnsureSetup(Setup);
        CodeFormat := ConfiguredFormat();
        exit(CodeFormat.Build(Setup."Last Serial Reference" + 1));
    end;

    /// <summary>
    /// Determines whether a code is well formed for the configured format.
    /// </summary>
    /// <param name="CodeValue">The code to check.</param>
    /// <returns>True when the code could have come from this warehouse.</returns>
    procedure IsValidCode(CodeValue: Code[20]): Boolean
    var
        CodeFormat: Interface "WHA ILabelCodeFormat";
    begin
        CodeFormat := ConfiguredFormat();
        exit(CodeFormat.IsValid(CodeValue));
    end;

    /// <summary>
    /// Describes the configured format in one line.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure DescribeFormat(): Text
    var
        CodeFormat: Interface "WHA ILabelCodeFormat";
    begin
        CodeFormat := ConfiguredFormat();
        exit(CodeFormat.Describe());
    end;

    /// <summary>
    /// Gives a handling unit a label code. Refuses a unit that already has one, because the code on the
    /// label and the code in the system have to be the same thing.
    /// </summary>
    /// <param name="HandlingUnit">The unit to label.</param>
    /// <returns>The code that was assigned.</returns>
    procedure AssignTo(var HandlingUnit: Record "WHA Handling Unit"): Code[20]
    var
        NewCode: Code[20];
    begin
        if HandlingUnit.SSCC <> '' then
            Error(AlreadyLabelledErr, HandlingUnit."No.", HandlingUnit.SSCC);
        if HandlingUnit.Status = HandlingUnit.Status::WHAShipped then
            Error(ShippedUnitErr, HandlingUnit."No.");

        NewCode := NextCode();
        HandlingUnit.Validate(SSCC, NewCode);
        HandlingUnit.Modify(true);

        exit(NewCode);
    end;

    /// <summary>
    /// Takes the next serial reference, counting up and never repeating. Locks the setup record first,
    /// so two people labelling at the same time cannot be given the same number.
    /// </summary>
    /// <returns>The next serial reference.</returns>
    procedure NextSerialReference(): BigInteger
    var
        Setup: Record "WHA Label Setup";
        LabelFeatureSetup: Codeunit "WHA Label Feature Setup";
    begin
        LabelFeatureSetup.EnsureSetup(Setup);

        Setup.LockTable();
        Setup.Get();
        Setup."Last Serial Reference" += 1;
        Setup.Modify(true);

        exit(Setup."Last Serial Reference");
    end;

    local procedure ConfiguredFormat(): Enum "WHA Label Code Format"
    var
        Setup: Record "WHA Label Setup";
        DefaultFormat: Enum "WHA Label Code Format";
    begin
        Setup.SetLoadFields(Format);
        if not Setup.Get() then
            exit(DefaultFormat);
        exit(Setup.Format);
    end;
}
