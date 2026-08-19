namespace WarehouseAdvanced.Packing;

page 50402 "WHA Pack Station Card"
{
    PageType = Card;
    ApplicationArea = WHAPacking;
    UsageCategory = None;
    SourceTable = "WHA Pack Station";
    Caption = 'Packing station';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
            }
            group(Placement)
            {
                Caption = 'Where it stands';

                field("Location Code"; Rec."Location Code")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(StationSessions)
            {
                Caption = 'Packed here';
                ToolTip = 'Specifies the action that shows the cartons packed at this bench.';
                Image = History;
                RunObject = page "WHA Pack Sessions";
                RunPageLink = "Station Code" = field("Code");
            }
        }
    }
}
