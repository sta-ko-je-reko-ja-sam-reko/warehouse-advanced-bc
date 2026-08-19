namespace WarehouseAdvanced.Integration;

using WarehouseAdvanced.Core;

page 50654 "WHA API Demo Integration"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoIntegration';
    APIVersion = 'v1.0';
    EntityName = 'demoIntegration';
    EntitySetName = 'demoIntegrationSet';
    EntityCaption = 'Demo integration';
    EntitySetCaption = 'Demo integration';
    Caption = 'Demo integration';
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
    /// Seeds the integration sample data. Exposed as the only tool in the demo integration MCP
    /// configuration. Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoIntegration: Codeunit "WHA Demo Integration";
    begin
        DemoIntegration.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
