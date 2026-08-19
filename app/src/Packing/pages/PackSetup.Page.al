namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

page 50400 "WHA Pack Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Pack Setup";
    Caption = 'Packing setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'pack, carton, box, packing bench, pack station';

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
                Caption = 'At the bench';

                field("Default Station Code"; Rec."Default Station Code")
                {
                    ApplicationArea = WHAPacking;
                }
                field("Require Verification"; Rec."Require Verification")
                {
                    ApplicationArea = WHAPacking;
                }
                field("Close Unit When Closed"; Rec."Close Unit When Closed")
                {
                    ApplicationArea = WHAPacking;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenStations)
            {
                Caption = 'Packing stations';
                ToolTip = 'Specifies the action that opens the list of packing benches.';
                Image = List;
                ApplicationArea = WHAPacking;
                RunObject = page "WHA Pack Stations";
            }
        }
    }

    trigger OnOpenPage()
    var
        PackFeatureSetup: Codeunit "WHA Pack Feature Setup";
    begin
        PackFeatureSetup.EnsureSetup(Rec);
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
