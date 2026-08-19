namespace WarehouseAdvanced.Labelling;

codeunit 50605 "WHA Sequential Format" implements "WHA ILabelCodeFormat"
{
    Access = Public;

    var
        DescriptionLbl: Label 'A plain licence plate: your prefix and a number that counts up. Fine inside your own warehouse, meaningless to anybody else.';

    /// <summary>
    /// Builds the licence plate for one serial reference: the configured prefix followed by a
    /// zero-padded number.
    /// </summary>
    /// <param name="SerialReference">The number the code is built around.</param>
    /// <returns>The code.</returns>
    procedure Build(SerialReference: BigInteger): Code[20]
    var
        Setup: Record "WHA Label Setup";
        Serial: Text;
    begin
        Setup.Get();

        Serial := Format(SerialReference);
        while StrLen(Serial) < SerialLength() do
            Serial := '0' + Serial;

        exit(CopyStr(DelChr(Setup."GS1 Company Prefix", '<>', ' ') + Serial, 1, 20));
    end;

    /// <summary>
    /// Determines whether a code looks like one of ours: the configured prefix, then digits.
    /// </summary>
    /// <param name="CodeValue">The code to check.</param>
    /// <returns>True when the code is well formed for this format.</returns>
    procedure IsValid(CodeValue: Code[20]): Boolean
    var
        Setup: Record "WHA Label Setup";
        Prefix: Text;
        Serial: Text;
    begin
        if not Setup.Get() then
            exit(false);

        Prefix := DelChr(Setup."GS1 Company Prefix", '<>', ' ');
        if StrLen(CodeValue) <> StrLen(Prefix) + SerialLength() then
            exit(false);
        if CopyStr(CodeValue, 1, StrLen(Prefix)) <> Prefix then
            exit(false);

        Serial := CopyStr(CodeValue, StrLen(Prefix) + 1);
        exit(DelChr(Serial, '=', '0123456789') = '');
    end;

    /// <summary>
    /// Describes the format in one line.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    local procedure SerialLength(): Integer
    begin
        exit(8);
    end;
}
