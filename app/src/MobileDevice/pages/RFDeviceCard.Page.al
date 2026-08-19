namespace WarehouseAdvanced.MobileDevice;

page 50102 "WHA RF Device Card"
{
    PageType = Card;
    ApplicationArea = WHAMobileDevice;
    UsageCategory = None;
    SourceTable = "WHA RF Device";
    Caption = 'Handheld device';

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
                field("Default Location Code"; Rec."Default Location Code")
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
            }
            group(Use)
            {
                Caption = 'Use';

                field("Last User ID"; Rec."Last User ID")
                {
                }
                field("Last Seen At"; Rec."Last Seen At")
                {
                }
            }
        }
    }
}
