namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;
using WarehouseAdvanced.Posting;

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
            group(Posting)
            {
                Caption = 'Writing off scrapped goods';

                field("Posting Method"; Rec."Posting Method")
                {
                    ApplicationArea = WHAQualityHold;

                    trigger OnValidate()
                    begin
                        DescribePostingMethod();
                    end;
                }
                field(PostingMethodDescription; PostingMethodDescription)
                {
                    Caption = 'What that does';
                    ToolTip = 'Specifies what scrapping goods will do to what Business Central believes is in stock, in full, so the choice above is made with its consequence in view.';
                    ApplicationArea = WHAQualityHold;
                    Editable = false;
                    MultiLine = true;
                }
                field("Item Journal Template Name"; Rec."Item Journal Template Name")
                {
                    ApplicationArea = WHAQualityHold;
                }
                field("Item Journal Batch Name"; Rec."Item Journal Batch Name")
                {
                    ApplicationArea = WHAQualityHold;
                }
                field("Posting Reason Code"; Rec."Posting Reason Code")
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
        DescribePostingMethod();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ApplyEnabledChangeIfNeeded();
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        DescribePostingMethod();
    end;

    var
        OpeningEnabled: Boolean;
        PostingMethodDescription: Text;

    local procedure DescribePostingMethod()
    var
        PostingMgt: Codeunit "WHA Posting Mgt.";
    begin
        PostingMethodDescription := PostingMgt.Describe(Rec."Posting Method");
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
