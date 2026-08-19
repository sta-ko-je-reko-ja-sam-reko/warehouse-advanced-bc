namespace WarehouseAdvanced.DockYard;

page 50453 "WHA Dock Appointments"
{
    PageType = List;
    ApplicationArea = WHADockYard;
    UsageCategory = Tasks;
    SourceTable = "WHA Dock Appointment";
    Caption = 'Dock appointments';
    CardPageId = "WHA Dock Appointment Card";
    SourceTableView = sorting("Location Code", "Expected At");

    layout
    {
        area(Content)
        {
            repeater(Appointments)
            {
                field("No."; Rec."No.")
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field(Direction; Rec.Direction)
                {
                }
                field("Expected At"; Rec."Expected At")
                {
                    StyleExpr = ExpectedStyle;
                }
                field("Dock Door Code"; Rec."Dock Door Code")
                {
                }
                field("Carrier Name"; Rec."Carrier Name")
                {
                }
                field("Trailer No."; Rec."Trailer No.")
                {
                }
                field(Reference; Rec.Reference)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Yard Position Code"; Rec."Yard Position Code")
                {
                }
                field("Arrived At"; Rec."Arrived At")
                {
                }
                field("At Door At"; Rec."At Door At")
                {
                }
                field("Departed At"; Rec."Departed At")
                {
                }
                field("Slot Minutes"; Rec."Slot Minutes")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CheckIn)
            {
                Caption = 'Check in';
                ToolTip = 'Specifies the action that records the vehicle as on site and parks it in the waiting position its door suggests. Open the card to park it somewhere else.';
                Image = ReceiveLoaner;

                trigger OnAction()
                begin
                    ApplyArrive();
                end;
            }
            action(ToTheDoor)
            {
                Caption = 'To the door';
                ToolTip = 'Specifies the action that brings a waiting vehicle onto its door and gives the yard position back.';
                Image = Bin;

                trigger OnAction()
                begin
                    ApplyMoveToDoor();
                end;
            }
            action(Depart)
            {
                Caption = 'Depart';
                ToolTip = 'Specifies the action that sends the vehicle off site and frees what it was holding.';
                Image = ShipmentLines;

                trigger OnAction()
                begin
                    ApplyDepart();
                end;
            }
            action(ChooseDoor)
            {
                Caption = 'Choose a door';
                ToolTip = 'Specifies the action that gives the booking whichever door the configured strategy can find for it.';
                Image = SelectEntries;

                trigger OnAction()
                begin
                    ApplyChooseDoor();
                end;
            }
            action(CancelBooking)
            {
                Caption = 'Call it off';
                ToolTip = 'Specifies the action that cancels the booking. The record that a vehicle was expected is kept.';
                Image = Cancel;

                trigger OnAction()
                begin
                    ApplyCancel();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CheckInRef; CheckIn)
                {
                }
                actionref(ToTheDoorRef; ToTheDoor)
                {
                }
                actionref(DepartRef; Depart)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetExpectedStyle();
    end;

    var
        ExpectedStyle: Text;
        AtDoorMsg: Label 'Appointment %1 is on door %2.', Comment = '%1 = the appointment number, %2 = the door code';
        DoorChosenMsg: Label 'Appointment %1 is booked onto door %2.', Comment = '%1 = the appointment number, %2 = the door code';
        NoDoorMsg: Label 'No door can take appointment %1 at that time, so it is booked without one.', Comment = '%1 = the appointment number';

    local procedure ApplyArrive()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        DockMgt.Arrive(Rec, DockMgt.SuggestedPosition(Rec));
        CurrPage.Update(false);
    end;

    local procedure ApplyMoveToDoor()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        Message(AtDoorMsg, Rec."No.", DockMgt.MoveToDoor(Rec));
        CurrPage.Update(false);
    end;

    local procedure ApplyDepart()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        DockMgt.Depart(Rec);
        CurrPage.Update(false);
    end;

    local procedure ApplyChooseDoor()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        DockMgt.AssignDoor(Rec, '');
        if Rec."Dock Door Code" <> '' then
            Message(DoorChosenMsg, Rec."No.", Rec."Dock Door Code")
        else
            Message(NoDoorMsg, Rec."No.");
        CurrPage.Update(false);
    end;

    local procedure ApplyCancel()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        DockMgt.Cancel(Rec);
        CurrPage.Update(false);
    end;

    local procedure SetExpectedStyle()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        if DockMgt.IsLate(Rec) then
            ExpectedStyle := 'Unfavorable'
        else
            ExpectedStyle := 'Standard';
    end;
}
