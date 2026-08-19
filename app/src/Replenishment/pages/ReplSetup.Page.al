namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

page 50250 "WHA Repl. Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Repl. Setup";
    Caption = 'Replenishment setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'replenishment, min max, top up, pick face';

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
            group(Rules)
            {
                Caption = 'New rules';

                field("Default Method"; Rec."Default Method")
                {
                    ApplicationArea = WHAReplenishment;
                }
                field("Default Priority"; Rec."Default Priority")
                {
                    ApplicationArea = WHAReplenishment;
                }
            }
            group(Running)
            {
                Caption = 'Running replenishment';

                field("Demand Method"; Rec."Demand Method")
                {
                    ApplicationArea = WHAReplenishment;

                    trigger OnValidate()
                    begin
                        DescribeDemand();
                    end;
                }
                field(DemandDescription; DemandDescription)
                {
                    Caption = 'What that takes into account';
                    ToolTip = 'Specifies what a run will weigh a bin against, in full, so the choice above is made with its consequence in view.';
                    ApplicationArea = WHAReplenishment;
                    Editable = false;
                    MultiLine = true;
                }
                field("Release Replenishment Work"; Rec."Release Replenishment Work")
                {
                    ApplicationArea = WHAReplenishment;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenRules)
            {
                Caption = 'Replenishment rules';
                ToolTip = 'Specifies the action that opens the list of replenishment rules.';
                Image = List;
                ApplicationArea = WHAReplenishment;
                RunObject = page "WHA Replenishment Rules";
            }
        }
    }

    trigger OnOpenPage()
    var
        ReplFeatureSetup: Codeunit "WHA Repl. Feature Setup";
    begin
        ReplFeatureSetup.EnsureSetup(Rec);
        OpeningEnabled := Rec."WHA Enabled";
        DescribeDemand();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ApplyEnabledChangeIfNeeded();
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        DescribeDemand();
    end;

    var
        OpeningEnabled: Boolean;
        DemandDescription: Text;

    local procedure DescribeDemand()
    var
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        DemandDescription := ReplenishmentMgt.DescribeDemand();
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
