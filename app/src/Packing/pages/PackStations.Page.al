namespace WarehouseAdvanced.Packing;

page 50401 "WHA Pack Stations"
{
    PageType = List;
    ApplicationArea = WHAPacking;
    UsageCategory = Lists;
    SourceTable = "WHA Pack Station";
    Caption = 'Packing stations';
    CardPageId = "WHA Pack Station Card";

    layout
    {
        area(Content)
        {
            repeater(Stations)
            {
                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenBench)
            {
                Caption = 'Go to the bench';
                ToolTip = 'Specifies the action that opens the packing screen, as somebody at the bench sees it.';
                Image = Start;
                RunObject = page "WHA Packing Station";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenBenchRef; OpenBench)
                {
                }
            }
        }
    }
}
