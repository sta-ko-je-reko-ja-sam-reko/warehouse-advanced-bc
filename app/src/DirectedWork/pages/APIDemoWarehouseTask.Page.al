namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

page 50204 "WHA API Demo Warehouse Task"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoDirectedWork';
    APIVersion = 'v1.0';
    EntityName = 'demoWarehouseTask';
    EntitySetName = 'demoWarehouseTaskSet';
    EntityCaption = 'Demo warehouse task';
    EntitySetCaption = 'Demo warehouse tasks';
    Caption = 'Demo warehouse tasks';
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
    /// Seeds the warehouse task sample data. Exposed as the only tool in the demo directed work MCP
    /// configuration. Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoWarehouseTask: Codeunit "WHA Demo Warehouse Task";
    begin
        DemoWarehouseTask.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
