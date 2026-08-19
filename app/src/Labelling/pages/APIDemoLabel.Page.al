namespace WarehouseAdvanced.Labelling;

using WarehouseAdvanced.Core;

page 50602 "WHA API Demo Label"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoLabelling';
    APIVersion = 'v1.0';
    EntityName = 'demoLabel';
    EntitySetName = 'demoLabelSet';
    EntityCaption = 'Demo label';
    EntitySetCaption = 'Demo labels';
    Caption = 'Demo labels';
    SourceTable = "WHA Demo Data";
    Extensible = false;
    Editable = false;

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
            }
        }
    }

    /// <summary>
    /// Sets a sample GS1 company prefix and labels the sample handling units that have no code yet.
    /// Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoLabel: Codeunit "WHA Demo Label";
    begin
        DemoLabel.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
