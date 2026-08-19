namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

page 50200 "WHA Warehouse Task Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Warehouse Task Setup";
    Caption = 'Warehouse task setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'directed work, task queue, operator, put-away, pick';

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
            group(Queue)
            {
                Caption = 'Queue';

                field("Default Priority"; Rec."Default Priority")
                {
                    ApplicationArea = WHADirectedWork;
                }
                field("Auto Release Tasks"; Rec."Auto Release Tasks")
                {
                    ApplicationArea = WHADirectedWork;
                }
                field("Follow Up Short Picks"; Rec."Follow Up Short Picks")
                {
                    ApplicationArea = WHADirectedWork;
                }
                field("Max Open Tasks Per User"; Rec."Max Open Tasks Per User")
                {
                    ApplicationArea = WHADirectedWork;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        TaskFeatureSetup: Codeunit "WHA Task Feature Setup";
    begin
        TaskFeatureSetup.EnsureSetup(Rec);
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
