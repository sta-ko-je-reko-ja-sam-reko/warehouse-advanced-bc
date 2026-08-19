namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

page 50506 "WHA API Demo Count"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoCounting';
    APIVersion = 'v1.0';
    EntityName = 'demoCount';
    EntitySetName = 'demoCountSet';
    EntityCaption = 'Demo count';
    EntitySetCaption = 'Demo counts';
    Caption = 'Demo counts';
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
    /// Seeds the counting sample data. Exposed as the only tool in the demo counting MCP configuration.
    /// Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoCount: Codeunit "WHA Demo Count";
    begin
        DemoCount.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
