namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;
using WarehouseAdvanced.Registration;

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
                field("Write Back To Document"; Rec."Write Back To Document")
                {
                    ApplicationArea = WHADirectedWork;
                }
            }
            group(Posting)
            {
                Caption = 'Posting';

                field("Open Work On Posting"; Rec."Open Work On Posting")
                {
                    ApplicationArea = WHADirectedWork;

                    trigger OnValidate()
                    begin
                        DescribeOpenWorkPolicy();
                    end;
                }
                field(OpenWorkPolicyDescription; OpenWorkPolicyDescription)
                {
                    Caption = 'What that does';
                    ToolTip = 'Specifies what posting a warehouse receipt or shipment will do about jobs raised from it that nobody has finished, in full.';
                    ApplicationArea = WHADirectedWork;
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(WarehouseRegistration)
            {
                Caption = 'Warehouse registration';

                field("Whse. Registration Method"; Rec."Whse. Registration Method")
                {
                    ApplicationArea = WHADirectedWork;

                    trigger OnValidate()
                    begin
                        DescribeRegistrationMethod();
                    end;
                }
                field(RegistrationMethodDescription; RegistrationMethodDescription)
                {
                    Caption = 'What that does';
                    ToolTip = 'Specifies what finishing a job will tell Business Central about the goods that moved, in full, so the choice above is made with its consequence in view.';
                    ApplicationArea = WHADirectedWork;
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Warehouse Task Nos."; Rec."Warehouse Task Nos.")
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

    trigger OnAfterGetRecord()
    begin
        DescribeRegistrationMethod();
        DescribeOpenWorkPolicy();
    end;

    var
        OpeningEnabled: Boolean;
        RegistrationMethodDescription: Text;
        OpenWorkPolicyDescription: Text;

    local procedure DescribeOpenWorkPolicy()
    var
        OpenWorkMgt: Codeunit "WHA Open Work Mgt.";
    begin
        OpenWorkPolicyDescription := OpenWorkMgt.Describe(Rec."Open Work On Posting");
    end;

    local procedure DescribeRegistrationMethod()
    var
        WhseRegMgt: Codeunit "WHA Whse. Reg. Mgt.";
    begin
        RegistrationMethodDescription := WhseRegMgt.Describe(Rec."Whse. Registration Method");
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
