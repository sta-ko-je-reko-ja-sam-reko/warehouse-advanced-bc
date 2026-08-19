namespace WarehouseAdvanced.Core;

page 50002 "WHA Feature Setup Wizard"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Warehouse advanced feature setup';

    layout
    {
        area(Content)
        {
            group(Intro)
            {
                Caption = 'About this step';
                Visible = IntroVisible;

                field(IntroFeatureName; FeatureName)
                {
                    Caption = 'Feature';
                    ToolTip = 'Specifies the feature that this step configures.';
                    Editable = false;
                }
                field(IntroDescription; FeatureDescription)
                {
                    Caption = 'About';
                    ToolTip = 'Specifies what the feature does.';
                    Editable = false;
                    MultiLine = true;
                }
                field(IntroRestartNote; RestartNoteLbl)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies that the session may restart when you close the setup list.';
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(Options)
            {
                Caption = 'Choose what to set up';
                Visible = OptionsVisible;

                field(OptionEnable; DoEnable)
                {
                    Caption = 'Enable this feature';
                    ToolTip = 'Specifies whether the feature is switched on.';
                    Enabled = HasToggle;
                }
                field(OptionNoSeries; DoCreateNoSeries)
                {
                    Caption = 'Create and assign number series';
                    ToolTip = 'Specifies whether the number series this feature needs is created and assigned automatically.';
                }
                field(OptionDemoData; DoImportDemoData)
                {
                    Caption = 'Load sample data';
                    ToolTip = 'Specifies whether example records for this feature are created in the current company.';
                }
                field(OptionDemoDataInfo; DemoDataInfoLbl)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies what loading sample data does.';
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(Done)
            {
                Caption = 'You are ready';
                Visible = DoneVisible;

                field(DoneText; DoneTextLbl)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies what happens when you choose Finish.';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BackAction)
            {
                Caption = 'Back';
                ToolTip = 'Specifies the action that returns to the previous step.';
                Image = PreviousRecord;
                Enabled = BackEnabled;
                InFooterBar = true;

                trigger OnAction()
                begin
                    SetStep(CurrentStep - 1);
                end;
            }
            action(NextAction)
            {
                Caption = 'Next';
                ToolTip = 'Specifies the action that continues to the next step.';
                Image = NextRecord;
                Enabled = NextEnabled;
                InFooterBar = true;

                trigger OnAction()
                begin
                    SetStep(CurrentStep + 1);
                end;
            }
            action(FinishAction)
            {
                Caption = 'Finish';
                ToolTip = 'Specifies the action that applies the choices and closes the wizard.';
                Image = Approve;
                Enabled = FinishEnabled;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ApplyChoices();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetStep(0);
    end;

    var
        TempSetupStep: Record "WHA Setup Step" temporary;
        FeatureName: Text[100];
        FeatureDescription: Text[250];
        HasToggle: Boolean;
        DoEnable: Boolean;
        DoCreateNoSeries: Boolean;
        DoImportDemoData: Boolean;
        CurrentStep: Integer;
        IntroVisible: Boolean;
        OptionsVisible: Boolean;
        DoneVisible: Boolean;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        RestartNoteLbl: Label 'Your session may restart when you close the setup list, so that the changes take effect. Finish the features you want to set up before closing it.';
        DemoDataInfoLbl: Label 'Sample data creates a small set of example records for this feature in the company you are working in. It is safe to run more than once because the same records are reused rather than duplicated. It builds on the standard demonstration company, so on an empty company only part of it is created. Review the examples before relying on them in a company you use for real work.';
        DoneTextLbl: Label 'Choose Finish to apply your choices. You return to the setup list, where you can set up the next feature.';

    /// <summary>
    /// Supplies the step this wizard configures. Call before running the page.
    /// </summary>
    /// <param name="SetupStep">The step selected in the setup hub.</param>
    internal procedure SetContext(var SetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep := SetupStep;
        FeatureName := SetupStep.Name;
        FeatureDescription := SetupStep.Description;
        HasToggle := SetupStep."Has Toggle";
        DoEnable := SetupStep.Enabled;
        DoCreateNoSeries := not SetupStep."Has Toggle";
        DoImportDemoData := false;
    end;

    local procedure SetStep(NewStep: Integer)
    begin
        CurrentStep := NewStep;

        IntroVisible := CurrentStep = 0;
        OptionsVisible := CurrentStep = 1;
        DoneVisible := CurrentStep = 2;

        BackEnabled := CurrentStep > 0;
        NextEnabled := CurrentStep < 2;
        FinishEnabled := CurrentStep = 2;

        CurrPage.Update(false);
    end;

    local procedure ApplyChoices()
    var
        GuidedSetup: Codeunit "WHA Guided Setup";
    begin
        GuidedSetup.ApplyWizardChoices(TempSetupStep, DoCreateNoSeries, DoImportDemoData);
    end;
}
