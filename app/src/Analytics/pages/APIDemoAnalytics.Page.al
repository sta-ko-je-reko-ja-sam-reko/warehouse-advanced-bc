namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.Core;

page 50704 "WHA API Demo Analytics"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoAnalytics';
    APIVersion = 'v1.0';
    EntityName = 'demoAnalytics';
    EntitySetName = 'demoAnalyticsSet';
    EntityCaption = 'Demo analytics';
    EntitySetCaption = 'Demo analytics';
    Caption = 'Demo analytics';
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
    /// Captures one set of KPI figures over the period the analytics setup asks for. Exposed as the only
    /// tool in the demo analytics MCP configuration. Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoAnalytics: Codeunit "WHA Demo Analytics";
    begin
        DemoAnalytics.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
