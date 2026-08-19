namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

page 50305 "WHA API Demo Slotting"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoSlotting';
    APIVersion = 'v1.0';
    EntityName = 'demoSlotting';
    EntitySetName = 'demoSlottingSet';
    EntityCaption = 'Demo slotting';
    EntitySetCaption = 'Demo slotting';
    Caption = 'Demo slotting';
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
    /// Runs the slotting analysis and proposals against whatever picking the company has already done.
    /// Exposed as the only tool in the demo slotting MCP configuration. Idempotent, and it does not enable
    /// the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoSlotting: Codeunit "WHA Demo Slotting";
    begin
        DemoSlotting.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
