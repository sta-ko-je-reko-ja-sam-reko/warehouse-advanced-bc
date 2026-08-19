namespace WarehouseAdvanced.HandlingUnit;

using WarehouseAdvanced.Core;

page 50050 "WHA Handling Unit Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Handling Unit Setup";
    Caption = 'Handling unit setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'pallet, container, license plate, SSCC';

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
            group(Nesting)
            {
                Caption = 'Nesting';

                field("Allow Nesting"; Rec."Allow Nesting")
                {
                    ApplicationArea = WHAHandlingUnits;
                }
                field("Max Nesting Depth"; Rec."Max Nesting Depth")
                {
                    ApplicationArea = WHAHandlingUnits;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Handling Unit Nos."; Rec."Handling Unit Nos.")
                {
                    ApplicationArea = WHAHandlingUnits;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        HUFeatureSetup: Codeunit "WHA HU Feature Setup";
    begin
        HUFeatureSetup.EnsureSetup(Rec);
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
