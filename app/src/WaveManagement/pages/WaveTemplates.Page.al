namespace WarehouseAdvanced.WaveManagement;

page 50155 "WHA Wave Templates"
{
    PageType = List;
    ApplicationArea = WHAWaveManagement;
    UsageCategory = Lists;
    SourceTable = "WHA Wave Template";
    Caption = 'Wave templates';
    CardPageId = "WHA Wave Template Card";

    layout
    {
        area(Content)
        {
            repeater(Templates)
            {
                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field(Strategy; Rec.Strategy)
                {
                }
                field("Max Tasks"; Rec."Max Tasks")
                {
                }
                field("Max Minutes"; Rec."Max Minutes")
                {
                }
                field("Release Automatically"; Rec."Release Automatically")
                {
                }
                field(Scheduled; Rec.Scheduled)
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
                field("Last Run At"; Rec."Last Run At")
                {
                }
                field("Last Wave No."; Rec."Last Wave No.")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BuildWave)
            {
                Caption = 'Build a wave';
                ToolTip = 'Specifies the action that builds a wave from this template now, gathers its work, and releases it if the template says so.';
                Image = CreateDocument;

                trigger OnAction()
                begin
                    BuildFromTemplate();
                end;
            }
            action(RunScheduledTemplates)
            {
                Caption = 'Run the scheduled templates';
                ToolTip = 'Specifies the action that builds a wave from every template marked for the scheduled run. It does the same thing the job queue entry does, so it can be tried by hand before it is scheduled.';
                Image = Refresh;

                trigger OnAction()
                begin
                    RunScheduledNow();
                end;
            }
        }
        area(Navigation)
        {
            action(TemplateWaves)
            {
                Caption = 'Waves built';
                ToolTip = 'Specifies the action that shows the waves this template has built.';
                Image = List;
                RunObject = page "WHA Waves";
                RunPageLink = "Template Code" = field("Code");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(BuildWaveRef; BuildWave)
                {
                }
                actionref(RunScheduledRef; RunScheduledTemplates)
                {
                }
            }
        }
    }

    var
        BuiltMsg: Label 'Wave %1 was built and gathered %2 job(s).', Comment = '%1 = the wave number, %2 = how many jobs it gathered';
        NothingGatheredMsg: Label 'There was no work for template %1 to gather, so no wave was created.', Comment = '%1 = the wave template code';
        ScheduledRunMsg: Label '%1 wave(s) built from the scheduled templates.', Comment = '%1 = how many waves were built';
        NoScheduledRunMsg: Label 'The scheduled templates found no work to gather, so no waves were created.';

    local procedure BuildFromTemplate()
    var
        Wave: Record "WHA Wave";
        WaveTemplateLogic: Codeunit "WHA Wave Template Logic";
        Gathered: Integer;
    begin
        Gathered := WaveTemplateLogic.CreateWave(Rec, Wave);
        if Gathered = 0 then
            Message(NothingGatheredMsg, Rec."Code")
        else
            Message(BuiltMsg, Wave."No.", Gathered);

        CurrPage.Update(false);
    end;

    local procedure RunScheduledNow()
    var
        WaveTemplateLogic: Codeunit "WHA Wave Template Logic";
        Built: Integer;
    begin
        Built := WaveTemplateLogic.RunScheduled('');
        if Built = 0 then
            Message(NoScheduledRunMsg)
        else
            Message(ScheduledRunMsg, Built);

        CurrPage.Update(false);
    end;
}
