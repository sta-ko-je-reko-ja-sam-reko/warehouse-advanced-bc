namespace WarehouseAdvanced.LabourManagement;

using WarehouseAdvanced.Core;

page 50350 "WHA Labour Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Labour Setup";
    Caption = 'Labour setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'labour, labor, productivity, standards, performance';

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
            group(Standards)
            {
                Caption = 'Measuring work';

                field("Default Basis"; Rec."Default Basis")
                {
                    ApplicationArea = WHALabourManagement;
                }
                field("Max Job Minutes"; Rec."Max Job Minutes")
                {
                    ApplicationArea = WHALabourManagement;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenStandards)
            {
                Caption = 'Labour standards';
                ToolTip = 'Specifies the action that opens the list of labour standards.';
                Image = List;
                ApplicationArea = WHALabourManagement;
                RunObject = page "WHA Labour Standards";
            }
            action(OpenEntries)
            {
                Caption = 'Recorded time';
                ToolTip = 'Specifies the action that opens the recorded time.';
                Image = Timesheet;
                ApplicationArea = WHALabourManagement;
                RunObject = page "WHA Labour Entries";
            }
        }
    }

    trigger OnOpenPage()
    var
        LabFeatureSetup: Codeunit "WHA Lab. Feature Setup";
    begin
        LabFeatureSetup.EnsureSetup(Rec);
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
