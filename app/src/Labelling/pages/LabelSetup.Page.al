namespace WarehouseAdvanced.Labelling;

using WarehouseAdvanced.Core;

page 50600 "WHA Label Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Label Setup";
    Caption = 'Labelling setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'SSCC, GS1, barcode, label, licence plate';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("WHA Enabled"; Rec."WHA Enabled")
                {
                }
            }
            group(Codes)
            {
                Caption = 'Label codes';

                field(Format; Rec.Format)
                {
                    ApplicationArea = WHALabelling;

                    trigger OnValidate()
                    begin
                        DescribeFormat();
                    end;
                }
                field(FormatDescription; FormatDescription)
                {
                    Caption = 'What the code looks like';
                    ToolTip = 'Specifies what a code in this format is made of.';
                    ApplicationArea = WHALabelling;
                    Editable = false;
                    MultiLine = true;
                }
                field("GS1 Company Prefix"; Rec."GS1 Company Prefix")
                {
                    ApplicationArea = WHALabelling;
                }
                field("Extension Digit"; Rec."Extension Digit")
                {
                    ApplicationArea = WHALabelling;
                }
                field("Last Serial Reference"; Rec."Last Serial Reference")
                {
                    ApplicationArea = WHALabelling;
                }
                field(NextExample; NextExample)
                {
                    Caption = 'Example';
                    ToolTip = 'Specifies what the next code would look like. It is only an example and is not given to anything.';
                    ApplicationArea = WHALabelling;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowExample)
            {
                Caption = 'Show an example code';
                ToolTip = 'Specifies the action that works out what the next code would look like, without using it up.';
                Image = Info;
                ApplicationArea = WHALabelling;

                trigger OnAction()
                begin
                    ShowExampleCode();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        LabelFeatureSetup: Codeunit "WHA Label Feature Setup";
    begin
        LabelFeatureSetup.EnsureSetup(Rec);
        OpeningEnabled := Rec."WHA Enabled";
        DescribeFormat();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ApplyEnabledChangeIfNeeded();
        exit(true);
    end;

    var
        OpeningEnabled: Boolean;
        FormatDescription: Text;
        NextExample: Text;

    local procedure DescribeFormat()
    var
        LabelMgt: Codeunit "WHA Label Mgt.";
    begin
        FormatDescription := LabelMgt.DescribeFormat();
    end;

    local procedure ShowExampleCode()
    var
        LabelMgt: Codeunit "WHA Label Mgt.";
    begin
        NextExample := LabelMgt.ExampleCode();
        CurrPage.Update(false);
    end;

    local procedure ApplyEnabledChangeIfNeeded()
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        if not Rec.Get() then
            exit;
        if Rec."WHA Enabled" = OpeningEnabled then
            exit;

        FeatureMgt.ApplyExperienceChange();
    end;
}
