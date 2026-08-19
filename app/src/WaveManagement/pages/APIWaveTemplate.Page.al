namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

page 50157 "WHA API Wave Template"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'waveManagement';
    APIVersion = 'v1.0';
    EntityName = 'waveTemplate';
    EntitySetName = 'waveTemplates';
    EntityCaption = 'Wave template';
    EntitySetCaption = 'Wave templates';
    SourceTable = "WHA Wave Template";
    DelayedInsert = true;
    Extensible = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(code; Rec."Code")
                {
                    Caption = 'Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(strategy; Rec.Strategy)
                {
                    Caption = 'Strategy';
                }
                field(maxTasks; Rec."Max Tasks")
                {
                    Caption = 'Max tasks';
                }
                field(maxMinutes; Rec."Max Minutes")
                {
                    Caption = 'Max minutes';
                }
                field(releaseAutomatically; Rec."Release Automatically")
                {
                    Caption = 'Release automatically';
                }
                field(scheduled; Rec.Scheduled)
                {
                    Caption = 'Scheduled';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(lastRunDateTime; Rec."Last Run At")
                {
                    Caption = 'Last run date time';
                    Editable = false;
                }
                field(lastWaveNumber; Rec."Last Wave No.")
                {
                    Caption = 'Last wave number';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified date time';
                    Editable = false;
                }
            }
        }
    }

    /// <summary>
    /// Builds a wave from this template now, gathers its work, and releases it when the template says so.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure BuildWave(var ActionContext: WebServiceActionContext)
    var
        Wave: Record "WHA Wave";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        WaveTemplateLogic.CreateWave(Rec, Wave);
        SetActionResponse(ActionContext);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        WaveTemplateLogic: Codeunit "WHA Wave Template Logic";

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"WHA API Wave Template");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
