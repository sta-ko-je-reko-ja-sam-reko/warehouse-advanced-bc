namespace WarehouseAdvanced.DockYard;

page 50454 "WHA Dock Appointment Card"
{
    PageType = Card;
    ApplicationArea = WHADockYard;
    UsageCategory = None;
    SourceTable = "WHA Dock Appointment";
    Caption = 'Dock appointment';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    Editable = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field(Direction; Rec.Direction)
                {
                }
                field("Dock Door Code"; Rec."Dock Door Code")
                {
                }
                field(Status; Rec.Status)
                {
                }
            }
            group(Vehicle)
            {
                Caption = 'Who is coming';

                field("Carrier Name"; Rec."Carrier Name")
                {
                }
                field("Trailer No."; Rec."Trailer No.")
                {
                }
                field(Reference; Rec.Reference)
                {
                }
            }
            group(Slot)
            {
                Caption = 'The slot';

                field("Expected At"; Rec."Expected At")
                {
                }
                field("Slot Minutes"; Rec."Slot Minutes")
                {
                }
            }
            group(Yard)
            {
                Caption = 'On site';

                field(PositionToPark; PositionToPark)
                {
                    Caption = 'Park in';
                    ToolTip = 'Specifies where to put the trailer when the vehicle is checked in. Leave it blank to use the waiting position the door suggests. It is only used by the check-in; where the trailer is standing now is below.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupPosition(Text));
                    end;
                }
                field("Yard Position Code"; Rec."Yard Position Code")
                {
                    Editable = false;
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
            }
            group(Audit)
            {
                Caption = 'Booking';

                field("Booked By User ID"; Rec."Booked By User ID")
                {
                }
                field("Created At"; Rec."Created At")
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
                ToolTip = 'Specifies the action that records the vehicle as on site and parks it where Park in says, or where its door suggests.';
                Image = ReceiveLoaner;

                trigger OnAction()
                begin
                    ApplyArrive();
                end;
            }
            action(ToTheDoor)
            {
                Caption = 'To the door';
                ToolTip = 'Specifies the action that brings the waiting vehicle onto its door and gives the yard position back.';
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

    var
        PositionToPark: Code[20];
        AtDoorMsg: Label 'Appointment %1 is on door %2.', Comment = '%1 = the appointment number, %2 = the door code';
        DoorChosenMsg: Label 'Appointment %1 is booked onto door %2.', Comment = '%1 = the appointment number, %2 = the door code';
        NoDoorMsg: Label 'No door can take appointment %1 at that time, so it stays without one.', Comment = '%1 = the appointment number';

    local procedure ApplyArrive()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
        ParkIn: Code[20];
    begin
        ParkIn := PositionToPark;
        if ParkIn = '' then
            ParkIn := DockMgt.SuggestedPosition(Rec);

        DockMgt.Arrive(Rec, ParkIn);
        PositionToPark := '';
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

    local procedure LookupPosition(var Selected: Text): Boolean
    var
        YardPosition: Record "WHA Yard Position";
    begin
        YardPosition.SetRange("Location Code", Rec."Location Code");
        if Page.RunModal(Page::"WHA Yard Positions", YardPosition) <> Action::LookupOK then
            exit(false);

        Selected := YardPosition."Code";
        exit(true);
    end;
}
