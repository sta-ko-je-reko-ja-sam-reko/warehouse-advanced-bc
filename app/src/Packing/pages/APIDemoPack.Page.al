namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

page 50407 "WHA API Demo Pack"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoPacking';
    APIVersion = 'v1.0';
    EntityName = 'demoPack';
    EntitySetName = 'demoPackSet';
    EntityCaption = 'Demo packing';
    EntitySetCaption = 'Demo packing';
    Caption = 'Demo packing';
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
    /// Seeds the packing sample data. Exposed as the only tool in the demo packing MCP configuration.
    /// Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoPack: Codeunit "WHA Demo Pack";
    begin
        DemoPack.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
