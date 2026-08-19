namespace WarehouseAdvanced.Core;

page 50001 "WHA Setup Hub"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Setup Step";
    Caption = 'Warehouse advanced setup';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    InstructionalText = 'Set up each feature in order. You can enable a feature, create its number series, and load sample data. When you close this page the session may restart so that the changes take effect, after which the app is ready to use.';

    layout
    {
        area(Content)
        {
            repeater(Steps)
            {
                field("Step No."; Rec."Step No.")
                {
                }
                field(Name; Rec.Name)
                {

                    trigger OnDrillDown()
                    begin
                        RunStep();
                    end;
                }
                field(Description; Rec.Description)
                {
                }
                field(Status; Rec.Status)
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetUpStep)
            {
                Caption = 'Set up';
                ToolTip = 'Specifies the action that opens the guided steps for the selected feature.';
                Image = Setup;

                trigger OnAction()
                begin
                    RunStep();
                end;
            }
            action(DetailedSetup)
            {
                Caption = 'Detailed setup';
                ToolTip = 'Specifies the action that opens the full setup page for the selected feature, for settings the guided steps do not cover.';
                Image = SetupLines;

                trigger OnAction()
                begin
                    OpenDetailedSetup();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SetUpStepRef; SetUpStep)
                {
                }
                actionref(DetailedSetupRef; DetailedSetup)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        GuidedSetup.PopulateSteps(Rec);
        OpeningFingerprint := FeatureMgt.GetEnabledFingerprint();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GuidedSetup.MarkAssistedSetupComplete();

        if FeatureMgt.GetEnabledFingerprint() <> OpeningFingerprint then
            FeatureMgt.RestartSession();

        exit(true);
    end;

    var
        GuidedSetup: Codeunit "WHA Guided Setup";
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        OpeningFingerprint: Text;

    local procedure RunStep()
    begin
        GuidedSetup.RunWizardForStep(Rec);
        GuidedSetup.PopulateSteps(Rec);
        CurrPage.Update(false);
    end;

    local procedure OpenDetailedSetup()
    begin
        if Rec."Setup Page ID" = 0 then
            exit;
        Page.Run(Rec."Setup Page ID");
    end;
}
