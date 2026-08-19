namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.Core;

page 50554 "WHA API Demo Quality Hold"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoQualityHold';
    APIVersion = 'v1.0';
    EntityName = 'demoQualityHold';
    EntitySetName = 'demoQualityHoldSet';
    EntityCaption = 'Demo quality hold';
    EntitySetCaption = 'Demo quality holds';
    Caption = 'Demo quality holds';
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
    /// Seeds the quality hold sample data. Exposed as the only tool in the demo quality hold MCP
    /// configuration. Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoQualityHold: Codeunit "WHA Demo Quality Hold";
    begin
        DemoQualityHold.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
