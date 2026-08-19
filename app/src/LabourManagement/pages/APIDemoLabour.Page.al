namespace WarehouseAdvanced.LabourManagement;

using WarehouseAdvanced.Core;

page 50355 "WHA API Demo Labour"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoLabourManagement';
    APIVersion = 'v1.0';
    EntityName = 'demoLabour';
    EntitySetName = 'demoLabourSet';
    EntityCaption = 'Demo labour';
    EntitySetCaption = 'Demo labour';
    Caption = 'Demo labour';
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
    /// Seeds the labour sample data. Exposed as the only tool in the demo labour MCP configuration.
    /// Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoLabour: Codeunit "WHA Demo Labour";
    begin
        DemoLabour.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
