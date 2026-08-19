namespace WarehouseAdvanced.MobileDevice;

using WarehouseAdvanced.Core;

page 50100 "WHA RF Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA RF Setup";
    Caption = 'Handheld setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'RF, scanner, handheld, terminal, mobile device';

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
            group(Behaviour)
            {
                Caption = 'On the floor';

                field(Flow; Rec.Flow)
                {
                    ApplicationArea = WHAMobileDevice;
                }
                field("Confirm By Scan"; Rec."Confirm By Scan")
                {
                    ApplicationArea = WHAMobileDevice;
                }
                field("Auto Start Task"; Rec."Auto Start Task")
                {
                    ApplicationArea = WHAMobileDevice;
                }
                field("Require Device Registration"; Rec."Require Device Registration")
                {
                    ApplicationArea = WHAMobileDevice;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Devices)
            {
                Caption = 'Handheld devices';
                ToolTip = 'Specifies the action that opens the list of registered handhelds.';
                Image = List;
                ApplicationArea = WHAMobileDevice;
                RunObject = page "WHA RF Devices";
            }
        }
    }

    trigger OnOpenPage()
    var
        RFFeatureSetup: Codeunit "WHA RF Feature Setup";
    begin
        RFFeatureSetup.EnsureSetup(Rec);
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
