namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

page 50458 "WHA API Demo Dock"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoDockYard';
    APIVersion = 'v1.0';
    EntityName = 'demoDockYard';
    EntitySetName = 'demoDockYardSet';
    EntityCaption = 'Demo dock and yard';
    EntitySetCaption = 'Demo dock and yard';
    Caption = 'Demo dock and yard';
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
    /// Seeds sample doors, yard positions and bookings at the first location the company has. Exposed as
    /// the only tool in the demo dock and yard MCP configuration. Idempotent, and it does not enable the
    /// feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoDock: Codeunit "WHA Demo Dock";
    begin
        DemoDock.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
