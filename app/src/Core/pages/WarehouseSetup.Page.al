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
    Editable = false;
    AdditionalSearchTerms = 'WMS, warehouse advanced, handling unit';

    layout
    {
        area(Content)
        {
            group(Foundation)
            {
                Caption = 'Foundation';

                field(FoundationInfo; FoundationInfoLbl)
                {
                    Caption = 'About these settings';
                    ToolTip = 'Specifies where the settings for each feature are kept.';
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
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

    var
        FoundationInfoLbl: Label 'There is nothing to fill in here. Every feature keeps its own settings on its own setup page, including the numbering it uses, so that a feature you never switch on asks you for nothing. Choose Guided setup to work through them.';
}
