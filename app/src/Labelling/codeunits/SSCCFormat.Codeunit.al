namespace WarehouseAdvanced.Labelling;

codeunit 50600 "WHA SSCC Format" implements "WHA ILabelCodeFormat"
{
    Access = Public;

    var
        PrefixMissingErr: Label 'Enter the GS1 company prefix in the labelling setup before making SSCC codes. Without it the codes would not identify this company.';
        PrefixNotNumericErr: Label 'The GS1 company prefix %1 has something in it that is not a digit. A GS1 company prefix is digits only.', Comment = '%1 = the company prefix as entered';
        PrefixTooLongErr: Label 'The GS1 company prefix %1 is %2 digits long. An SSCC has room for a prefix of at most 15 digits, and in practice GS1 issues 7 to 10.', Comment = '%1 = the company prefix as entered, %2 = how many digits it has';
        OutOfNumbersErr: Label 'The serial reference no longer fits beside a %1-digit company prefix. Every SSCC this prefix can produce has been used.', Comment = '%1 = how many digits the company prefix has';
        DescriptionLbl: Label 'An 18-digit GS1 SSCC: your extension digit, your company prefix, a serial number, and a check digit.';

    /// <summary>
    /// Builds the SSCC for one serial reference: extension digit, GS1 company prefix, the reference
    /// padded to fill the code, and the GS1 check digit over all of it.
    /// </summary>
    /// <param name="SerialReference">The number the code is built around.</param>
    /// <returns>The code, 18 digits.</returns>
    procedure Build(SerialReference: BigInteger): Code[20]
    var
        Setup: Record "WHA Label Setup";
        DataDigits: Text;
        Prefix: Text;
        SerialLength: Integer;
    begin
        Setup.Get();
        Prefix := DelChr(Setup."GS1 Company Prefix", '<>', ' ');

        if Prefix = '' then
            Error(PrefixMissingErr);
        if not IsAllDigits(Prefix) then
            Error(PrefixNotNumericErr, Prefix);
        if StrLen(Prefix) > MaxPrefixLength() then
            Error(PrefixTooLongErr, Prefix, StrLen(Prefix));

        SerialLength := DataLength() - 1 - StrLen(Prefix);
        DataDigits := Format(Setup."Extension Digit") + Prefix + SerialText(SerialReference, SerialLength, StrLen(Prefix));

        exit(CopyStr(DataDigits + Format(CheckDigit(DataDigits)), 1, 20));
    end;

    /// <summary>
    /// Determines whether a code is a well-formed SSCC: eighteen digits whose last one is the check
    /// digit of the other seventeen.
    /// </summary>
    /// <param name="CodeValue">The code to check.</param>
    /// <returns>True when the code is a valid SSCC.</returns>
    procedure IsValid(CodeValue: Code[20]): Boolean
    var
        DataDigits: Text;
        GivenCheck: Integer;
    begin
        if StrLen(CodeValue) <> DataLength() + 1 then
            exit(false);
        if not IsAllDigits(CodeValue) then
            exit(false);

        DataDigits := CopyStr(CodeValue, 1, DataLength());
        if not Evaluate(GivenCheck, CopyStr(CodeValue, DataLength() + 1, 1)) then
            exit(false);

        exit(GivenCheck = CheckDigit(DataDigits));
    end;

    /// <summary>
    /// Describes the format in one line.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Calculates the GS1 check digit over the data part of a code. Every digit is weighted three or one
    /// alternately, counting from the right, and the check digit is what takes the total up to a
    /// multiple of ten.
    /// </summary>
    /// <param name="DataDigits">The digits the check digit is calculated over.</param>
    /// <returns>The check digit, zero to nine.</returns>
    procedure CheckDigit(DataDigits: Text): Integer
    var
        Position: Integer;
        Weight: Integer;
        DigitValue: Integer;
        Total: Integer;
    begin
        Weight := 3;
        for Position := StrLen(DataDigits) downto 1 do begin
            if Evaluate(DigitValue, CopyStr(DataDigits, Position, 1)) then
                Total += DigitValue * Weight;
            if Weight = 3 then
                Weight := 1
            else
                Weight := 3;
        end;

        exit((10 - (Total mod 10)) mod 10);
    end;

    local procedure SerialText(SerialReference: BigInteger; SerialLength: Integer; PrefixLength: Integer): Text
    var
        Serial: Text;
    begin
        Serial := Format(SerialReference);
        if StrLen(Serial) > SerialLength then
            Error(OutOfNumbersErr, PrefixLength);

        while StrLen(Serial) < SerialLength do
            Serial := '0' + Serial;

        exit(Serial);
    end;

    local procedure IsAllDigits(Value: Text): Boolean
    begin
        if Value = '' then
            exit(false);
        exit(DelChr(Value, '=', '0123456789') = '');
    end;

    local procedure DataLength(): Integer
    begin
        exit(17);
    end;

    local procedure MaxPrefixLength(): Integer
    begin
        exit(15);
    end;
}
