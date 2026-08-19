namespace WarehouseAdvanced.Core;

page 50000 "WHA Warehouse Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Warehouse Setup";
    Caption = 'Warehouse advanced setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'WMS, warehouse advanced, handling unit';

    layout
    {
        area(Content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Handling Unit Nos."; Rec."Handling Unit Nos.")
                {
                }
                field("Warehouse Task Nos."; Rec."Warehouse Task Nos.")
                {
                }
                field("Wave Nos."; Rec."Wave Nos.")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GuidedSetup)
            {
                Caption = 'Guided setup';
                ToolTip = 'Specifies the action that opens the guided setup, where each feature can be enabled and configured in order.';
                Image = Setup;
                RunObject = page "WHA Setup Hub";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(GuidedSetupRef; GuidedSetup)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        SetupLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        SetupLogic.EnsureExists(Rec);
    end;
}
