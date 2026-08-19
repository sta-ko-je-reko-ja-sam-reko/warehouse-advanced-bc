namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.Core;

page 50700 "WHA Analytics Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Analytics Setup";
    Caption = 'Analytics setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'KPI, analytics, throughput, dock to stock, performance';

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
            group(Period)
            {
                Caption = 'What a figure covers';

                field("Default Period Days"; Rec."Default Period Days")
                {
                    ApplicationArea = WHAAnalytics;
                }
                field("Capture Location Code"; Rec."Capture Location Code")
                {
                    ApplicationArea = WHAAnalytics;
                }
                field("Catch Up Days"; Rec."Catch Up Days")
                {
                    ApplicationArea = WHAAnalytics;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CaptureNow)
            {
                Caption = 'Capture the figures now';
                ToolTip = 'Specifies the action that works out every measure for the period and keeps the answers, so that this period can be compared with the next.';
                Image = Calculate;
                ApplicationArea = WHAAnalytics;

                trigger OnAction()
                begin
                    ApplyCapture();
                end;
            }
        }
        area(Navigation)
        {
            action(OpenKPIs)
            {
                Caption = 'Warehouse KPIs';
                ToolTip = 'Specifies the action that opens the figures worked out on the spot.';
                Image = Statistics;
                ApplicationArea = WHAAnalytics;
                RunObject = page "WHA Warehouse KPIs";
            }
            action(OpenSnapshots)
            {
                Caption = 'KPI snapshots';
                ToolTip = 'Specifies the action that opens the figures that have been kept.';
                Image = History;
                ApplicationArea = WHAAnalytics;
                RunObject = page "WHA KPI Snapshots";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CaptureNowRef; CaptureNow)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        KPIFeatureSetup: Codeunit "WHA KPI Feature Setup";
    begin
        KPIFeatureSetup.EnsureSetup(Rec);
        OpeningEnabled := Rec."WHA Enabled";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ApplyEnabledChangeIfNeeded();
        exit(true);
    end;

    var
        OpeningEnabled: Boolean;
        CapturedMsg: Label '%1 figure(s) were captured.', Comment = '%1 = how many figures were kept';

    local procedure ApplyCapture()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
    begin
        Message(CapturedMsg, KpiMgt.Capture(Rec."Capture Location Code", 0D, 0D));
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
