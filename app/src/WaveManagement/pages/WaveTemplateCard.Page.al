namespace WarehouseAdvanced.WaveManagement;

page 50156 "WHA Wave Template Card"
{
    PageType = Card;
    ApplicationArea = WHAWaveManagement;
    UsageCategory = None;
    SourceTable = "WHA Wave Template";
    Caption = 'Wave template';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
            }
            group(WhatItGathers)
            {
                Caption = 'What it gathers';

                field(Strategy; Rec.Strategy)
                {
                }
                field("Max Tasks"; Rec."Max Tasks")
                {
                }
                field("Max Minutes"; Rec."Max Minutes")
                {
                }
                field(TemplateDescription; TemplateDescription)
                {
                    Caption = 'What that builds';
                    ToolTip = 'Specifies what a wave from this template will gather and what happens to it, so the settings above can be read as one sentence.';
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(Running)
            {
                Caption = 'Running it';

                field("Release Automatically"; Rec."Release Automatically")
                {
                }
                field(Scheduled; Rec.Scheduled)
                {
                }
                field("Last Run At"; Rec."Last Run At")
                {
                }
                field("Last Wave No."; Rec."Last Wave No.")
                {
                }
                field("Wave Count"; Rec."Wave Count")
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
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescribeTemplate();
    end;

    var
        TemplateDescription: Text;
        BuiltMsg: Label 'Wave %1 was built and gathered %2 job(s).', Comment = '%1 = the wave number, %2 = how many jobs it gathered';
        NothingGatheredMsg: Label 'There was no work for this template to gather, so no wave was created.';

    local procedure DescribeTemplate()
    var
        WaveTemplateLogic: Codeunit "WHA Wave Template Logic";
    begin
        TemplateDescription := WaveTemplateLogic.Describe(Rec);
    end;

    local procedure BuildFromTemplate()
    var
        Wave: Record "WHA Wave";
        WaveTemplateLogic: Codeunit "WHA Wave Template Logic";
        Gathered: Integer;
    begin
        Gathered := WaveTemplateLogic.CreateWave(Rec, Wave);
        if Gathered = 0 then
            Message(NothingGatheredMsg)
        else
            Message(BuiltMsg, Wave."No.", Gathered);

        CurrPage.Update(false);
    end;
}
