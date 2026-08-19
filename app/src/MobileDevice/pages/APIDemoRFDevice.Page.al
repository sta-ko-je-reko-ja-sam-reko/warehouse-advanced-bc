namespace WarehouseAdvanced.MobileDevice;

using WarehouseAdvanced.Core;

page 50105 "WHA API Demo RF Device"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoMobileDevice';
    APIVersion = 'v1.0';
    EntityName = 'demoHandheldDevice';
    EntitySetName = 'demoHandheldDeviceSet';
    EntityCaption = 'Demo handheld device';
    EntitySetCaption = 'Demo handheld devices';
    Caption = 'Demo handheld devices';
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
    /// Seeds the handheld sample data. Exposed as the only tool in the demo mobile device MCP
    /// configuration. Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoRFDevice: Codeunit "WHA Demo RF Device";
    begin
        DemoRFDevice.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
