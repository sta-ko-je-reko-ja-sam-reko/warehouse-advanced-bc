namespace WarehouseAdvanced.DockYard;

using Microsoft.Inventory.Location;
using System.Security.AccessControl;

table 50453 "WHA Dock Appointment"
{
    Caption = 'Dock appointment';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Dock Appointments";
    DrillDownPageId = "WHA Dock Appointments";
    DataCaptionFields = "No.", "Carrier Name";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies the appointment.';
            NotBlank = true;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the site the vehicle is coming to. An appointment is for one site, because the doors and the yard belong to one.';
            TableRelation = Location;
        }
        field(11; Direction; Enum "WHA Dock Direction")
        {
            Caption = 'Direction';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the vehicle is bringing goods in or taking them out. A door that does not take this direction cannot be given the booking.';
        }
        field(12; "Dock Door Code"; Code[20])
        {
            Caption = 'Door';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the door the vehicle is booked onto. Leave it blank and one is chosen for you when the booking is made.';
            TableRelation = "WHA Dock Door"."Code" where("Location Code" = field("Location Code"));
        }
        field(20; "Carrier Name"; Text[100])
        {
            Caption = 'Carrier';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies who is coming. The haulier rather than the driver, because the driver changes and the booking does not.';
        }
        field(21; "Trailer No."; Code[20])
        {
            Caption = 'Trailer no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the trailer or vehicle the yard has to find again. This is what somebody reads off the unit standing in front of them.';
        }
        field(22; Reference; Text[50])
        {
            Caption = 'Reference';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the vehicle is here for, in whatever the yard quotes on the gate: an order, a load, or a shipment number.';
        }
        field(30; "Expected At"; DateTime)
        {
            Caption = 'Expected at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the vehicle is booked in. This is the promise, and how late it turns up is measured against it.';
        }
        field(31; "Slot Minutes"; Integer)
        {
            Caption = 'Slot minutes';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how long the booking occupies the door. Two bookings whose slots overlap cannot share a door.';
            MinValue = 0;
        }
        field(32; Status; Enum "WHA Appointment Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the vehicle is in its visit: booked, on site, at the door, gone, or called off.';
            Editable = false;
        }
        field(40; "Arrived At"; DateTime)
        {
            Caption = 'Arrived at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the vehicle reported to the gate. Everything the yard is judged on is measured from this.';
            Editable = false;
        }
        field(41; "At Door At"; DateTime)
        {
            Caption = 'At the door at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the vehicle was put on the door. The gap back to the arrival is what the driver spent waiting.';
            Editable = false;
        }
        field(42; "Departed At"; DateTime)
        {
            Caption = 'Departed at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the vehicle left the site. The gap back to the arrival is the turnaround.';
            Editable = false;
        }
        field(50; "Yard Position Code"; Code[20])
        {
            Caption = 'Yard position';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the trailer is standing while it waits. Cleared when the vehicle goes to a door or leaves, so it says where the trailer is now.';
            TableRelation = "WHA Yard Position"."Code" where("Location Code" = field("Location Code"));
            Editable = false;
        }
        field(60; "Booked By User ID"; Code[50])
        {
            Caption = 'Booked by';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who made the booking.';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(61; "Created At"; DateTime)
        {
            Caption = 'Created at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the booking was made, which is not the same as when the vehicle was expected.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Schedule; "Location Code", "Expected At")
        {
        }
        key(Door; "Location Code", "Dock Door Code", Status)
        {
        }
        key(Standing; Status, "Location Code")
        {
        }
        key(Yard; "Location Code", "Yard Position Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Carrier Name", "Expected At", Status)
        {
        }
        fieldgroup(Brick; "No.", "Carrier Name", "Trailer No.", "Expected At", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    trigger OnDelete()
    begin
        Logic().Trigger_OnDelete(Rec);
    end;

    var
        ILogic: Interface "WHA IDockAppointment";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the dock appointment logic. Used by tests to supply a fake
    /// and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IDockAppointment")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IDockAppointment"
    var
        DefaultLogic: Codeunit "WHA Dock Appt. Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
