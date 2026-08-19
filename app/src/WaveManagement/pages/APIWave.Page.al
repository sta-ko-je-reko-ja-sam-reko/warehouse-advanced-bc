namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

page 50153 "WHA API Wave"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'waveManagement';
    APIVersion = 'v1.0';
    EntityName = 'wave';
    EntitySetName = 'waves';
    EntityCaption = 'Wave';
    EntitySetCaption = 'Waves';
    SourceTable = "WHA Wave";
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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
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
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(taskCount; Rec."Task Count")
                {
                    Caption = 'Task count';
                    Editable = false;
                }
                field(completedTaskCount; Rec."Completed Task Count")
                {
                    Caption = 'Completed task count';
                    Editable = false;
                }
                field(releasedDateTime; Rec."Released At")
                {
                    Caption = 'Released date time';
                    Editable = false;
                }
                field(completedDateTime; Rec."Completed At")
                {
                    Caption = 'Completed date time';
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
    /// Gathers work into the wave, using its strategy.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Fill(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        WaveLogic.Fill(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Sends every job in the wave to the floor at once.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Release(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        WaveLogic.Release(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Closes the wave once all of its work is finished.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Complete(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        WaveLogic.Complete(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Withdraws the wave and cancels any of its work that nobody has started.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Cancel(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAWaveManagement);
        WaveLogic.Cancel(Rec);
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
        WaveLogic: Codeunit "WHA Wave Logic";

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"WHA API Wave");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
