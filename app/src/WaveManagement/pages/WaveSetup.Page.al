namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

page 50150 "WHA Wave Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Wave Setup";
    Caption = 'Wave setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'wave, batch, release, pick round';

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
            group(Building)
            {
                Caption = 'Building a wave';

                field("Default Strategy"; Rec."Default Strategy")
                {
                    ApplicationArea = WHAWaveManagement;
                }
                field("Default Max Tasks"; Rec."Default Max Tasks")
                {
                    ApplicationArea = WHAWaveManagement;
                }
                field("Include Unreleased Work"; Rec."Include Unreleased Work")
                {
                    ApplicationArea = WHAWaveManagement;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Wave Nos."; Rec."Wave Nos.")
                {
                    ApplicationArea = WHAWaveManagement;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenWaves)
            {
                Caption = 'Waves';
                ToolTip = 'Specifies the action that opens the list of waves.';
                Image = List;
                ApplicationArea = WHAWaveManagement;
                RunObject = page "WHA Waves";
            }
        }
    }

    trigger OnOpenPage()
    var
        WaveFeatureSetup: Codeunit "WHA Wave Feature Setup";
    begin
        WaveFeatureSetup.EnsureSetup(Rec);
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
