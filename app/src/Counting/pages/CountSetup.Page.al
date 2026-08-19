namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;
using WarehouseAdvanced.Posting;

page 50500 "WHA Count Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Count Setup";
    Caption = 'Counting setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'counting, cycle count, stocktake, blind count';

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
            group(Sheets)
            {
                Caption = 'New count sheets';

                field("Default Selection"; Rec."Default Selection")
                {
                    ApplicationArea = WHACounting;
                }
                field("Blind Counting"; Rec."Blind Counting")
                {
                    ApplicationArea = WHACounting;
                }
            }
            group(Differences)
            {
                Caption = 'Differences';

                field("Tolerance Quantity"; Rec."Tolerance Quantity")
                {
                    ApplicationArea = WHACounting;
                }
                field("Tolerance Percent"; Rec."Tolerance Percent")
                {
                    ApplicationArea = WHACounting;
                }
                field("Approve Variances"; Rec."Approve Variances")
                {
                    ApplicationArea = WHACounting;
                }
            }
            group(Posting)
            {
                Caption = 'Posting';

                field("Posting Method"; Rec."Posting Method")
                {
                    ApplicationArea = WHACounting;

                    trigger OnValidate()
                    begin
                        DescribePostingMethod();
                    end;
                }
                field(PostingMethodDescription; PostingMethodDescription)
                {
                    Caption = 'What that does';
                    ToolTip = 'Specifies what closing a count sheet will do about its differences, in full, so the choice above is made with its consequence in view.';
                    ApplicationArea = WHACounting;
                    Editable = false;
                    MultiLine = true;
                }
                field("Item Journal Template Name"; Rec."Item Journal Template Name")
                {
                    ApplicationArea = WHACounting;
                }
                field("Item Journal Batch Name"; Rec."Item Journal Batch Name")
                {
                    ApplicationArea = WHACounting;
                }
                field("Posting Reason Code"; Rec."Posting Reason Code")
                {
                    ApplicationArea = WHACounting;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Count Sheet Nos."; Rec."Count Sheet Nos.")
                {
                    ApplicationArea = WHACounting;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenCountSheets)
            {
                Caption = 'Count sheets';
                ToolTip = 'Specifies the action that opens the list of count sheets.';
                Image = List;
                ApplicationArea = WHACounting;
                RunObject = page "WHA Count Sheets";
            }
        }
    }

    trigger OnOpenPage()
    var
        CountFeatureSetup: Codeunit "WHA Count Feature Setup";
    begin
        CountFeatureSetup.EnsureSetup(Rec);
        OpeningEnabled := Rec."WHA Enabled";
        DescribePostingMethod();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ApplyEnabledChangeIfNeeded();
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        DescribePostingMethod();
    end;

    var
        OpeningEnabled: Boolean;
        PostingMethodDescription: Text;

    local procedure DescribePostingMethod()
    var
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        PostingMethodDescription := PostingMgt.Describe(Rec."Posting Method");
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
