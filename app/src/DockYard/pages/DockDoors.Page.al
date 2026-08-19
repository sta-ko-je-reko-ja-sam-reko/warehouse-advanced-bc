namespace WarehouseAdvanced.DockYard;

page 50451 "WHA Dock Doors"
{
    PageType = List;
    ApplicationArea = WHADockYard;
    UsageCategory = Lists;
    SourceTable = "WHA Dock Door";
    Caption = 'Dock doors';

    layout
    {
        area(Content)
        {
            repeater(Doors)
            {
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Direction; Rec.Direction)
                {
                }
                field(Blocked; Rec.Blocked)
                {
                    StyleExpr = BlockedStyle;
                }
                field("Yard Position Code"; Rec."Yard Position Code")
                {
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ShowAppointments)
            {
                Caption = 'Appointments';
                ToolTip = 'Specifies the action that opens the vehicles booked onto this door.';
                Image = List;
                RunObject = page "WHA Dock Appointments";
                RunPageLink = "Location Code" = field("Location Code"), "Dock Door Code" = field("Code");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowAppointmentsRef; ShowAppointments)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetBlockedStyle();
    end;

    var
        BlockedStyle: Text;

    local procedure SetBlockedStyle()
    begin
        if Rec.Blocked then
            BlockedStyle := 'Unfavorable'
        else
            BlockedStyle := 'Standard';
    end;
}
