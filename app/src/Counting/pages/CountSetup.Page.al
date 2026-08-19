namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

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
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ApplyEnabledChangeIfNeeded();
        exit(true);
    end;

    var
        OpeningEnabled: Boolean;

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
