namespace WarehouseAdvanced.Labelling;

using WarehouseAdvanced.Core;
using WarehouseAdvanced.HandlingUnit;

page 50601 "WHA API Label"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'labelling';
    APIVersion = 'v1.0';
    EntityName = 'labelledHandlingUnit';
    EntitySetName = 'labelledHandlingUnits';
    EntityCaption = 'Labelled handling unit';
    EntitySetCaption = 'Labelled handling units';
    SourceTable = "WHA Handling Unit";
    Extensible = false;
    Editable = false;
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
                field(labelCode; Rec.SSCC)
                {
                    Caption = 'Label code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
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
    /// Gives this handling unit a label code in the configured format. Refuses a unit that already has
    /// one, because the code on the label and the code in the system have to agree.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure AssignLabel(var ActionContext: WebServiceActionContext)
    var
        LabelMgt: Codeunit "WHA Label Mgt.";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHALabelling);
        LabelMgt.AssignTo(Rec);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"WHA API Label");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
