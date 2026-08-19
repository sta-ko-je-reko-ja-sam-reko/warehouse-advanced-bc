namespace WarehouseAdvanced.MobileDevice;

page 50101 "WHA RF Devices"
{
    PageType = List;
    ApplicationArea = WHAMobileDevice;
    UsageCategory = Lists;
    SourceTable = "WHA RF Device";
    Caption = 'Handheld devices';
    CardPageId = "WHA RF Device Card";

    layout
    {
        area(Content)
        {
            repeater(Devices)
            {
                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Default Location Code"; Rec."Default Location Code")
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
                field("Last User ID"; Rec."Last User ID")
                {
                }
                field("Last Seen At"; Rec."Last Seen At")
                {
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Handheld)
            {
                Caption = 'Open handheld';
                ToolTip = 'Specifies the action that opens the handheld screen, as an operator sees it.';
                Image = Start;
                RunObject = page "WHA RF Handheld";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(HandheldRef; Handheld)
                {
                }
            }
        }
    }
}
