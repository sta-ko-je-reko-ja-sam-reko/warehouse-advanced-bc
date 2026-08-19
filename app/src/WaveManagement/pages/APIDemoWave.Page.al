namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.Core;

page 50154 "WHA API Demo Wave"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'demoWaveManagement';
    APIVersion = 'v1.0';
    EntityName = 'demoWave';
    EntitySetName = 'demoWaveSet';
    EntityCaption = 'Demo wave';
    EntitySetCaption = 'Demo waves';
    Caption = 'Demo waves';
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
    /// Seeds the wave sample data. Exposed as the only tool in the demo wave management MCP
    /// configuration. Idempotent, and it does not enable the feature.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure ImportDemoData(var ActionContext: WebServiceActionContext)
    var
        DemoWave: Codeunit "WHA Demo Wave";
    begin
        DemoWave.Import();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;
}
