namespace WarehouseAdvanced.DockYard;

page 50452 "WHA Yard Positions"
{
    PageType = List;
    ApplicationArea = WHADockYard;
    UsageCategory = Lists;
    SourceTable = "WHA Yard Position";
    Caption = 'Yard positions';

    layout
    {
        area(Content)
        {
            repeater(Positions)
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
                field("Occupied By Appt. No."; Rec."Occupied By Appt. No.")
                {
                    StyleExpr = OccupiedStyle;
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
            action(ShowAppointment)
            {
                Caption = 'Appointment';
                ToolTip = 'Specifies the action that opens the booking of whatever is standing here.';
                Image = List;
                RunObject = page "WHA Dock Appointments";
                RunPageLink = "No." = field("Occupied By Appt. No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowAppointmentRef; ShowAppointment)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetOccupiedStyle();
    end;

    var
        OccupiedStyle: Text;

    local procedure SetOccupiedStyle()
    begin
        if Rec."Occupied By Appt. No." <> '' then
            OccupiedStyle := 'Attention'
        else
            OccupiedStyle := 'Standard';
    end;
}
