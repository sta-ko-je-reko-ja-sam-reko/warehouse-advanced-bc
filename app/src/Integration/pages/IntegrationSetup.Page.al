namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

page 50650 "WHA Integration Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Integration Setup";
    Caption = 'Integration setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'interface, message, inbox, outbox, host system';

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
            group(Messages)
            {
                Caption = 'Messages';

                field("Partner System"; Rec."Partner System")
                {
                    ApplicationArea = WHAIntegration;
                }
                field("Auto Process Inbound"; Rec."Auto Process Inbound")
                {
                    ApplicationArea = WHAIntegration;
                }
                field("Max Retry Count"; Rec."Max Retry Count")
                {
                    ApplicationArea = WHAIntegration;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenMessages)
            {
                Caption = 'Integration messages';
                ToolTip = 'Specifies the action that opens the messages exchanged with the partner system.';
                Image = Log;
                ApplicationArea = WHAIntegration;
                RunObject = page "WHA Integration Messages";
            }
        }
    }

    trigger OnOpenPage()
    var
        IntFeatureSetup: Codeunit "WHA Int. Feature Setup";
    begin
        IntFeatureSetup.EnsureSetup(Rec);
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
