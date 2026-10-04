codeunit 59005 "WHA Labelling Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PrefixTok: Label '0801234', Locked = true;

    [Test]
    procedure TheCheckDigitMatchesTheGS1Standard()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
    begin
        // [SCENARIO] The check digit is the one thing here a trading partner verifies with their own
        // software, so it is anchored to a barcode that exists in the world rather than to our own
        // output. 4006381333931 is a real EAN-13 whose check digit is 1; the same modulo-10 calculation
        // serves GTIN and SSCC alike.
        Assert.AreEqual(1, SSCCFormat.CheckDigit('400638133393'), 'The published EAN 4006381333931 has check digit 1.');

        // And three worked by hand against the rule — weights of three and one alternating from the
        // rightmost data digit, the check digit being whatever takes the total to a multiple of ten.
        Assert.AreEqual(0, SSCCFormat.CheckDigit('00000000000000000'), 'All zeroes total zero, so the check digit is zero.');
        Assert.AreEqual(7, SSCCFormat.CheckDigit('00000000000000001'), 'A single one at weight three totals three, so the check digit is seven.');
        Assert.AreEqual(8, SSCCFormat.CheckDigit('00801234000000000'), 'The sample prefix totals forty-two, so the check digit is eight.');
    end;

    [Test]
    procedure AGeneratedSSCCIsEighteenDigitsAndValid()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
        Generated: Code[20];
    begin
        // [SCENARIO] Anything we print has to pass the same check a partner's scanner applies.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);

        Generated := SSCCFormat.Build(42);

        Assert.AreEqual(18, StrLen(Generated), 'An SSCC is eighteen digits.');
        Assert.IsTrue(SSCCFormat.IsValid(Generated), 'A code we generated should pass our own validation.');
    end;

    [Test]
    procedure TheSameReferenceAlwaysGivesTheSameCode()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
    begin
        // [SCENARIO] Building a code is a calculation, not an event. That is what lets the setup page
        // show an example without spending a number.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);

        Assert.AreEqual(SSCCFormat.Build(7), SSCCFormat.Build(7), 'The same serial reference should always give the same code.');
        Assert.AreNotEqual(SSCCFormat.Build(7), SSCCFormat.Build(8), 'Different serial references should give different codes.');
    end;

    [Test]
    procedure TheCodeCarriesTheExtensionDigitAndPrefix()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
        Generated: Code[20];
    begin
        // [SCENARIO] An SSCC says who made it. If the prefix is not in there, the code identifies nobody.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 3);

        Generated := SSCCFormat.Build(1);

        Assert.AreEqual('3', CopyStr(Generated, 1, 1), 'The first digit should be the extension digit.');
        Assert.AreEqual(PrefixTok, CopyStr(Generated, 2, StrLen(PrefixTok)), 'The company prefix should follow the extension digit.');
    end;

    [Test]
    procedure ABadCheckDigitIsRejected()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
        Generated: Code[20];
        Tampered: Code[20];
    begin
        // [SCENARIO] The point of a check digit is catching a code that was mistyped or misread. If we
        // accept one, we have thrown that away.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);
        Generated := SSCCFormat.Build(99);

        Tampered := CopyStr(CopyStr(Generated, 1, 17) + WrongLastDigit(Generated), 1, 20);

        Assert.IsFalse(SSCCFormat.IsValid(Tampered), 'A code with the wrong check digit should be refused.');
    end;

    [Test]
    procedure SomethingThatIsNotAnSSCCIsRejected()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
    begin
        // [SCENARIO] Codes arrive from outside, where a typo and a real code look alike.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);

        Assert.IsFalse(SSCCFormat.IsValid('123'), 'A short code is not an SSCC.');
        Assert.IsFalse(SSCCFormat.IsValid('00801234000000ABC1'), 'A code with letters in it is not an SSCC.');
        Assert.IsFalse(SSCCFormat.IsValid(''), 'An empty code is not an SSCC.');
    end;

    [Test]
    procedure AMissingCompanyPrefixIsRefused()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
    begin
        // [SCENARIO] There is no safe default for a number GS1 issued to one company, so the app asks
        // rather than inventing one.
        ConfigureLabelling('', 0);

        asserterror SSCCFormat.Build(1);

        Assert.ExpectedError('company prefix');
    end;

    [Test]
    procedure ACompanyPrefixWithLettersIsRefused()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
    begin
        // [SCENARIO] A prefix that is not digits produces a code no scanner will read, and the failure
        // would only show up on a pallet at a customer's gate.
        ConfigureLabelling('08A1234', 0);

        asserterror SSCCFormat.Build(1);

        Assert.ExpectedError('not a digit');
    end;

    [Test]
    procedure TheSequentialFormatIsPrefixAndNumber()
    var
        SequentialFormat: Codeunit "WHA Sequential Format";
        Generated: Code[20];
    begin
        // [SCENARIO] A warehouse with no GS1 prefix still needs licence plates, and they only have to
        // mean something inside its own walls.
        ConfigureLabelling('LP', 0);
        SetFormatToSequential();

        Generated := SequentialFormat.Build(15);

        Assert.AreEqual('LP00000015', Generated, 'A licence plate should be the prefix and a padded number.');
        Assert.IsTrue(SequentialFormat.IsValid(Generated), 'A code we generated should pass our own validation.');
    end;

    [Test]
    procedure TakingACodeUsesUpTheNumber()
    var
        Setup: Record "WHA Label Setup";
        LabelMgt: Codeunit "WHA Label Mgt.";
        FirstCode: Code[20];
        SecondCode: Code[20];
    begin
        // [SCENARIO] Two pallets wearing the same label is the worst thing this feature could do, so the
        // counter only ever goes up.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);

        FirstCode := LabelMgt.NextCode();
        SecondCode := LabelMgt.NextCode();

        Assert.AreNotEqual(FirstCode, SecondCode, 'Two codes taken in a row should never be the same.');

        Setup.Get();
        Assert.AreEqual(2, Setup."Last Serial Reference", 'Each code taken should use up one number.');
    end;

    [Test]
    procedure AnExampleDoesNotUseUpANumber()
    var
        Setup: Record "WHA Label Setup";
        LabelMgt: Codeunit "WHA Label Mgt.";
        FirstExample: Code[20];
        SecondExample: Code[20];
    begin
        // [SCENARIO] Somebody checking their prefix looks right must not burn label codes doing it.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);

        FirstExample := LabelMgt.ExampleCode();
        SecondExample := LabelMgt.ExampleCode();

        Assert.AreEqual(FirstExample, SecondExample, 'Asking for an example twice should give the same answer.');

        Setup.Get();
        Assert.AreEqual(0, Setup."Last Serial Reference", 'An example should not use up a number.');
    end;

    [Test]
    procedure LabellingAUnitPutsTheCodeOnIt()
    var
        HandlingUnit: Record "WHA Handling Unit";
        LabelMgt: Codeunit "WHA Label Mgt.";
        AssignedCode: Code[20];
    begin
        // [SCENARIO] This closes the gap handling units left open: the SSCC field existed, and nothing
        // could fill it.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);
        CreateUnit(HandlingUnit, 'LBL-HU-001');

        AssignedCode := LabelMgt.AssignTo(HandlingUnit);

        HandlingUnit.Get('LBL-HU-001');
        Assert.AreEqual(AssignedCode, HandlingUnit.SSCC, 'The unit should carry the code it was given.');
        Assert.IsTrue(LabelMgt.IsValidCode(HandlingUnit.SSCC), 'The code on the unit should be well formed.');
    end;

    [Test]
    procedure AUnitIsNotLabelledTwice()
    var
        HandlingUnit: Record "WHA Handling Unit";
        LabelMgt: Codeunit "WHA Label Mgt.";
    begin
        // [SCENARIO] A label is printed and stuck on. Giving the unit a second code means the pallet and
        // the system disagree, and the pallet is the one people believe.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);
        CreateUnit(HandlingUnit, 'LBL-HU-002');
        LabelMgt.AssignTo(HandlingUnit);

        asserterror LabelMgt.AssignTo(HandlingUnit);

        Assert.ExpectedError('already carries');
    end;

    [Test]
    procedure AShippedUnitIsNotLabelled()
    var
        HandlingUnit: Record "WHA Handling Unit";
        LabelMgt: Codeunit "WHA Label Mgt.";
    begin
        // [SCENARIO] Labelling something that has left the building achieves nothing except using up a
        // code.
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);
        CreateUnit(HandlingUnit, 'LBL-HU-003');
        HandlingUnit.Status := HandlingUnit.Status::WHAShipped;
        HandlingUnit.Modify(true);

        asserterror LabelMgt.AssignTo(HandlingUnit);

        Assert.ExpectedError('already been shipped');
    end;

    [Test]
    procedure DemoImportIsIdempotent()
    var
        HandlingUnit: Record "WHA Handling Unit";
        DemoHandlingUnit: Codeunit "WHA Demo Handling Unit";
        DemoLabel: Codeunit "WHA Demo Label";
        FirstCode: Code[20];
    begin
        // [SCENARIO] Re-running the sample data must not relabel a unit. The first code is the one on
        // the sticker.
        DemoHandlingUnit.Import();
        DemoLabel.Import();

        HandlingUnit.Get('DEMO-HU-003');
        FirstCode := HandlingUnit.SSCC;

        DemoLabel.Import();

        HandlingUnit.Get('DEMO-HU-003');
        Assert.AreNotEqual('', FirstCode, 'The sample data should have labelled the unlabelled unit.');
        Assert.AreEqual(FirstCode, HandlingUnit.SSCC, 'A second run should leave the code it already had.');
    end;

    [Test]
    procedure APrefixRunsOutOfSerialNumbers()
    var
        SSCCFormat: Codeunit "WHA SSCC Format";
        LastCode: Code[20];
    begin
        // [SCENARIO] A ten-digit prefix leaves six digits for the serial reference. The last of them still
        // makes a valid code; the one after it would need a seventh digit and is refused, rather than
        // silently producing a code some other pallet already wears.
        // [GIVEN] A ten-digit company prefix
        ConfigureLabelling('0801234567', 0);

        // [WHEN] The last serial reference that fits is used
        LastCode := SSCCFormat.Build(999999);
        // [THEN] It is a valid eighteen-digit code
        Assert.AreEqual(18, StrLen(LastCode), 'The last code that fits is still eighteen digits.');
        Assert.IsTrue(SSCCFormat.IsValid(LastCode), 'The last code that fits is valid.');

        // [WHEN] The next one is asked for
        asserterror SSCCFormat.Build(1000000);
        // [THEN] It is refused
        Assert.ExpectedError('The serial reference no longer fits beside a 10-digit company prefix.');
    end;

    [Test]
    procedure TheSequentialFormatIsUsedWhenTheSetupChoosesIt()
    var
        LabelMgt: Codeunit "WHA Label Mgt.";
        SequentialDescription: Text;
    begin
        // [SCENARIO] The format is chosen in the setup and reached through the label management, so that
        // is the path that has to switch from SSCC to sequential numbers.
        // [GIVEN] A prefix of LP and the sequential format
        ConfigureLabelling('LP', 0);
        SetFormatToSequential();

        // [WHEN] The next code is taken
        // [THEN] It is the prefix followed by eight digits
        Assert.AreEqual('LP00000001', LabelMgt.NextCode(), 'The first sequential code is the prefix and serial one.');

        // [THEN] Codes are recognised by their prefix and length
        Assert.IsTrue(LabelMgt.IsValidCode('LP00000042'), 'A code with the prefix and eight digits is valid.');
        Assert.IsFalse(LabelMgt.IsValidCode('XX00000042'), 'A code with another prefix is not.');
        Assert.IsFalse(LabelMgt.IsValidCode('LP0000042'), 'A code one digit short is not.');
        Assert.IsFalse(LabelMgt.IsValidCode('LP0000004A'), 'A code with a letter in the serial is not.');

        // [THEN] The format describes itself differently from SSCC
        SequentialDescription := LabelMgt.DescribeFormat();
        ConfigureLabelling('LP', 0);
        Assert.AreNotEqual(SequentialDescription, LabelMgt.DescribeFormat(), 'Each format describes itself.');
    end;

    [Test]
    procedure TakingACodeMovesTheSerialReferenceOn()
    var
        Setup: Record "WHA Label Setup";
        LabelMgt: Codeunit "WHA Label Mgt.";
    begin
        // [GIVEN] A setup whose last serial reference is forty-one
        ConfigureLabelling(CopyStr(PrefixTok, 1, 10), 0);
        Setup.Get();
        Setup."Last Serial Reference" := 41;
        Setup.Modify(false);

        // [WHEN] The next serial reference is taken
        // [THEN] It is forty-two, and the setup remembers it
        Assert.AreEqual(42, LabelMgt.NextSerialReference(), 'The next reference follows the last.');
        Setup.Get();
        Assert.AreEqual(42, Setup."Last Serial Reference", 'The setup remembers the reference that was taken.');
    end;

    local procedure ConfigureLabelling(CompanyPrefix: Code[10]; ExtensionDigit: Integer)
    var
        Setup: Record "WHA Label Setup";
        DefaultFormat: Enum "WHA Label Code Format";
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;

        Setup."GS1 Company Prefix" := CompanyPrefix;
        Setup."Extension Digit" := ExtensionDigit;
        Setup."Last Serial Reference" := 0;
        Setup.Format := DefaultFormat::WHASSCC;
        Setup.Modify(true);
    end;

    local procedure SetFormatToSequential()
    var
        Setup: Record "WHA Label Setup";
        SequentialFormat: Enum "WHA Label Code Format";
    begin
        Setup.Get();
        Setup.Format := SequentialFormat::WHASequential;
        Setup.Modify(true);
    end;

    local procedure CreateUnit(var HandlingUnit: Record "WHA Handling Unit"; UnitNo: Code[20])
    begin
        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit.Insert(true);
    end;

    local procedure WrongLastDigit(CodeValue: Code[20]): Text
    var
        LastDigit: Integer;
    begin
        Evaluate(LastDigit, CopyStr(CodeValue, StrLen(CodeValue), 1));
        exit(Format((LastDigit + 1) mod 10));
    end;
}
