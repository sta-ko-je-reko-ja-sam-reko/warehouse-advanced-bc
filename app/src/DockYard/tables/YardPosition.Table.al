namespace WarehouseAdvanced.DockYard;

using Microsoft.Inventory.Location;

table 50452 "WHA Yard Position"
{
    Caption = 'Yard position';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Yard Positions";
    DrillDownPageId = "WHA Yard Positions";
    DataCaptionFields = "Location Code", "Code";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the yard position belongs to.';
            TableRelation = Location;
            NotBlank = true;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code that identifies the parking place. Use the number painted on the ground, because somebody has to find the trailer again.';
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where in the yard this is, in the words the yard uses.';
        }
        field(11; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the position is out of use. Nothing new is parked in a blocked position; a trailer already in it is left alone.';
        }
        field(20; "Occupied By Appt. No."; Code[20])
        {
            Caption = 'Occupied by';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the appointment whose vehicle is standing here. Filled in when a vehicle is parked and cleared when it leaves, so it is always what is out there now rather than what was.';
            TableRelation = "WHA Dock Appointment"."No.";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Location Code", "Code")
        {
            Clustered = true;
        }
        key(Occupancy; "Location Code", "Occupied By Appt. No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Occupied By Appt. No.")
        {
        }
        fieldgroup(Brick; "Code", Description, "Occupied By Appt. No.", Blocked)
        {
        }
    }
}
