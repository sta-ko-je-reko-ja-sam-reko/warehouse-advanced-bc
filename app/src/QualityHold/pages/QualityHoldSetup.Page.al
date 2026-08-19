namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;

page 50550 "WHA Quality Hold Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Quality Hold Setup";
    Caption = 'Quality hold setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'quality, quarantine, hold, block, inspection, scrap';

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
            group(Holding)
            {
                Caption = 'Placing a hold';

                field("Default Reason"; Rec."Default Reason")
                {
                    ApplicationArea = WHAQualityHold;
                }
                field("Hold Nested Units"; Rec."Hold Nested Units")
                {
                    ApplicationArea = WHAQualityHold;
                }
            }
            group(Releasing)
            {
                Caption = 'Lifting a hold';

                field("Require Disposition"; Rec."Require Disposition")
                {
                    ApplicationArea = WHAQualityHold;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenHolds)
            {
                Caption = 'Quality holds';
                ToolTip = 'Specifies the action that opens the list of quality holds.';
                Image = List;
                ApplicationArea = WHAQualityHold;
                RunObject = page "WHA Quality Holds";
            }
        }
    }

    trigger OnOpenPage()
    var
        QCFeatureSetup: Codeunit "WHA QC Feature Setup";
    begin
        QCFeatureSetup.EnsureSetup(Rec);
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
