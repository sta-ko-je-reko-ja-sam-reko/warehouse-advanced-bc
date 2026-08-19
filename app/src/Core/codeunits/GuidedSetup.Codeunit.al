namespace WarehouseAdvanced.Core;

using System.Environment.Configuration;
using System.Media;

codeunit 50002 "WHA Guided Setup"
{
    Access = Internal;

    var
        AssistedSetupTitleLbl: Label 'Set up Warehouse Advanced';
        AssistedSetupShortTitleLbl: Label 'Warehouse Advanced';
        AssistedSetupDescriptionLbl: Label 'Work through the warehouse advanced features in order. Enable the features you need and give each one the settings it requires.';
        FoundationStepNameLbl: Label 'Foundation';
        FoundationStepDescriptionLbl: Label 'The record every warehouse advanced feature builds on. Always active, and there is nothing to fill in: each feature keeps its own settings, its own numbering included.';

    /// <summary>
    /// Fills the step buffer with the foundation step plus every feature that registers one, then
    /// computes each step's status.
    /// </summary>
    /// <param name="TempSetupStep">The temporary buffer to populate. Existing rows are discarded.</param>
    internal procedure PopulateSteps(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Reset();
        TempSetupStep.DeleteAll();

        AddFoundationStep(TempSetupStep);
        AddFeatureSteps(TempSetupStep);

        ComputeStatuses(TempSetupStep);

        if TempSetupStep.FindFirst() then;
    end;

    /// <summary>
    /// Runs the wizard for the selected step and returns when the user closes it.
    /// </summary>
    /// <param name="TempSetupStep">The step to configure.</param>
    internal procedure RunWizardForStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    var
        FeatureSetupWizard: Page "WHA Feature Setup Wizard";
    begin
        FeatureSetupWizard.SetContext(TempSetupStep);
        FeatureSetupWizard.RunModal();
    end;

    /// <summary>
    /// Applies the choices made in the wizard. Refreshes the application areas but never restarts the
    /// session, because the hub owns the single deferred restart.
    /// </summary>
    /// <param name="TempSetupStep">The step the choices belong to.</param>
    /// <param name="Enable">Whether the feature should be switched on.</param>
    /// <param name="CreateNoSeries">Whether the feature should create and assign the numbering it needs. Features that number nothing ignore it.</param>
    /// <param name="ImportDemoData">Whether to load the feature's sample data.</param>
    internal procedure ApplyWizardChoices(var TempSetupStep: Record "WHA Setup Step" temporary; Enable: Boolean; CreateNoSeries: Boolean; ImportDemoData: Boolean)
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        if TempSetupStep."Has Toggle" then begin
            FeatureSetup := TempSetupStep.Feature;
            FeatureSetup.ApplyChoices(Enable, CreateNoSeries, ImportDemoData);
        end else
            EnsureFoundation();

        FeatureMgt.RefreshExperienceAreas();
    end;

    /// <summary>
    /// Registers the guided setup on the Microsoft assisted setup list. Safe to call repeatedly.
    /// </summary>
    internal procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if GuidedExperience.Exists(Enum::"Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"WHA Setup Hub") then
            exit;

        GuidedExperience.InsertAssistedSetup(
            AssistedSetupTitleLbl,
            AssistedSetupShortTitleLbl,
            AssistedSetupDescriptionLbl,
            5,
            ObjectType::Page,
            Page::"WHA Setup Hub",
            Enum::"Assisted Setup Group"::Uncategorized,
            '',
            Enum::"Video Category"::Uncategorized,
            '');
    end;

    /// <summary>
    /// Marks the guided setup as completed on the assisted setup list.
    /// </summary>
    internal procedure MarkAssistedSetupComplete()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"WHA Setup Hub");
    end;

    local procedure AddFoundationStep(var TempSetupStep: Record "WHA Setup Step" temporary)
    begin
        TempSetupStep.Init();
        TempSetupStep."Step No." := 10;
        TempSetupStep.Feature := TempSetupStep.Feature::WHANone;
        TempSetupStep."Has Toggle" := false;
        TempSetupStep.Name := CopyStr(FoundationStepNameLbl, 1, MaxStrLen(TempSetupStep.Name));
        TempSetupStep.Description := CopyStr(FoundationStepDescriptionLbl, 1, MaxStrLen(TempSetupStep.Description));
        TempSetupStep."Setup Page ID" := Page::"WHA Warehouse Setup";
        TempSetupStep.Insert(true);
    end;

    local procedure AddFeatureSteps(var TempSetupStep: Record "WHA Setup Step" temporary)
    var
        FeatureSetup: Interface "WHA IFeatureSetup";
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            FeatureSetup := Enum::"WHA Feature".FromInteger(Ordinal);
            FeatureSetup.RegisterStep(TempSetupStep);
        end;
    end;

    local procedure ComputeStatuses(var TempSetupStep: Record "WHA Setup Step" temporary)
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        if not TempSetupStep.FindSet() then
            exit;

        repeat
            if TempSetupStep."Has Toggle" then begin
                TempSetupStep.Enabled := FeatureMgt.IsEnabled(TempSetupStep.Feature);
                TempSetupStep.Status := StatusFor(TempSetupStep.Enabled);
            end else begin
                TempSetupStep.Enabled := true;
                TempSetupStep.Status := StatusFor(IsFoundationComplete());
            end;
            TempSetupStep.Modify(true);
        until TempSetupStep.Next() = 0;
    end;

    local procedure StatusFor(Completed: Boolean): Enum "WHA Setup Step Status"
    var
        Status: Enum "WHA Setup Step Status";
    begin
        if Completed then
            exit(Status::WHACompleted);
        exit(Status::WHANotStarted);
    end;

    local procedure IsFoundationComplete(): Boolean
    var
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        exit(SetupLogic.IsComplete());
    end;

    local procedure EnsureFoundation()
    var
        WarehouseSetup: Record "WHA Warehouse Setup";
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        SetupLogic.EnsureExists(WarehouseSetup);
    end;
}
