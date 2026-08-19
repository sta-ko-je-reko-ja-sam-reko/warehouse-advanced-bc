namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

page 50653 "WHA API Integration Message"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'integration';
    APIVersion = 'v1.0';
    EntityName = 'integrationMessage';
    EntitySetName = 'integrationMessages';
    EntityCaption = 'Integration message';
    EntitySetCaption = 'Integration messages';
    SourceTable = "WHA Integration Message";
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
                field(entryNumber; Rec."Entry No.")
                {
                    Caption = 'Entry number';
                    Editable = false;
                }
                field(direction; Rec.Direction)
                {
                    Caption = 'Direction';
                }
                field(messageType; Rec."Message Type")
                {
                    Caption = 'Message type';
                }
                field(partnerSystem; Rec."Partner System")
                {
                    Caption = 'Partner system';
                }
                field(externalId; Rec."External Id")
                {
                    Caption = 'External ID';
                }
                field(correlationId; Rec."Correlation Id")
                {
                    Caption = 'Correlation ID';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error message';
                    Editable = false;
                }
                field(retryCount; Rec."Retry Count")
                {
                    Caption = 'Retry count';
                    Editable = false;
                }
                field(payload; PayloadText)
                {
                    Caption = 'Payload';
                }
                field(receivedDateTime; Rec."Received At")
                {
                    Caption = 'Received date time';
                    Editable = false;
                }
                field(processedDateTime; Rec."Processed At")
                {
                    Caption = 'Processed date time';
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
    /// Applies this inbound message. Use it when messages are not processed on arrival, or to try a
    /// failed message again after the reason for the failure has been dealt with.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Process(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAIntegration);
        MessageMgt.Process(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Records that the partner system has collected this outbound message, so it is not offered again.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Acknowledge(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAIntegration);
        MessageMgt.Acknowledge(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Drops this message without acting on it, keeping it as a record that it arrived.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Cancel(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAIntegration);
        MessageMgt.Cancel(Rec);
        SetActionResponse(ActionContext);
    end;

    trigger OnAfterGetRecord()
    begin
        PayloadText := MessageMgt.GetPayload(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAIntegration);
        MessageMgt.SetPayload(Rec, PayloadText);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAIntegration);
        MessageMgt.SetPayload(Rec, PayloadText);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAIntegration);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        PayloadText: Text;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"WHA API Integration Message");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
