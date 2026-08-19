namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

page 50504 "WHA API Count Sheet"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'counting';
    APIVersion = 'v1.0';
    EntityName = 'countSheet';
    EntitySetName = 'countSheets';
    EntityCaption = 'Count sheet';
    EntitySetCaption = 'Count sheets';
    SourceTable = "WHA Count Sheet";
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
                field(selection; Rec.Selection)
                {
                    Caption = 'Selection';
                }
                field(blind; Rec.Blind)
                {
                    Caption = 'Blind';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due date';
                }
                field(assignedToUserId; Rec."Assigned To User ID")
                {
                    Caption = 'Assigned to user ID';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting date';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(lineCount; Rec."Line Count")
                {
                    Caption = 'Line count';
                    Editable = false;
                }
                field(countedLineCount; Rec."Counted Line Count")
                {
                    Caption = 'Counted line count';
                    Editable = false;
                }
                field(varianceLineCount; Rec."Variance Line Count")
                {
                    Caption = 'Variance line count';
                    Editable = false;
                }
                field(unapprovedVarianceCount; Rec."Unapproved Variance Count")
                {
                    Caption = 'Unapproved variance count';
                    Editable = false;
                }
                field(startedDateTime; Rec."Started At")
                {
                    Caption = 'Started date time';
                    Editable = false;
                }
                field(countedDateTime; Rec."Counted At")
                {
                    Caption = 'Counted date time';
                    Editable = false;
                }
                field(closedDateTime; Rec."Closed At")
                {
                    Caption = 'Closed date time';
                    Editable = false;
                }
                field(posted; Rec.Posted)
                {
                    Caption = 'Posted';
                    Editable = false;
                }
                field(postingDocumentNumber; Rec."Posting Document No.")
                {
                    Caption = 'Posting document number';
                    Editable = false;
                }
                field(postedDateTime; Rec."Posted At")
                {
                    Caption = 'Posted date time';
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
    /// Puts a line on the sheet for everything its selection finds at the location.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Fill(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        CountSheetLogic.Fill(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Sends the sheet to the floor to be counted.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Start(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        CountSheetLogic.Start(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Marks the sheet as counted once every line has been counted.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Complete(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        CountSheetLogic.Complete(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Closes the sheet, once every difference beyond the tolerance has been approved, and hands its
    /// differences to the posting method set up for counting.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Close(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        CountSheetLogic.Close(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Withdraws the sheet, keeping whatever was counted so far as a record.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Cancel(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        CountSheetLogic.Cancel(Rec);
        SetActionResponse(ActionContext);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        CountSheetLogic: Codeunit "WHA Count Sheet Logic";

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"WHA API Count Sheet");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
