namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

page 50254 "WHA API Demo Repl."
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoReplenishment';
    APIVersion = 'v1.0';
    EntityName = 'demoReplenishment';
    EntitySetName = 'demoReplenishmentSet';
    EntityCaption = 'Demo replenishment';
    EntitySetCaption = 'Demo replenishment';
    Caption = 'Demo replenishment';
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
    /// Seeds the replenishment sample data. Exposed as the only tool in the demo replenishment MCP
    /// configuration. Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoReplenishment: Codeunit "WHA Demo Replenishment";
    begin
        DemoReplenishment.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
