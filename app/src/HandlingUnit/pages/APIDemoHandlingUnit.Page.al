namespace WarehouseAdvanced.HandlingUnit;

using WarehouseAdvanced.Core;

page 50054 "WHA API Demo Handling Unit"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoHandlingUnit';
    APIVersion = 'v1.0';
    EntityName = 'demoHandlingUnit';
    EntitySetName = 'demoHandlingUnitSet';
    EntityCaption = 'Demo handling unit';
    EntitySetCaption = 'Demo handling units';
    Caption = 'Demo handling units';
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
    /// Seeds the handling unit sample data. Exposed as the only tool in the demo handling unit MCP
    /// configuration. Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoHandlingUnit: Codeunit "WHA Demo Handling Unit";
    begin
        DemoHandlingUnit.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
