namespace WarehouseAdvanced.DockYard;

using Microsoft.Inventory.Location;

table 50451 "WHA Dock Door"
{
    Caption = 'Dock door';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Dock Doors";
    DrillDownPageId = "WHA Dock Doors";
    DataCaptionFields = "Location Code", "Code";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the door belongs to. A door code only has to be unique within its own site.';
            TableRelation = Location;
            NotBlank = true;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code that identifies the door. Use what is painted above it, because that is what the driver will be told.';
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the door is, in the words the yard uses.';
        }
        field(11; Direction; Enum "WHA Door Direction")
        {
            Caption = 'Takes';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which way goods move through this door. A booking cannot be given a door that does not take its direction.';
        }
        field(12; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the door is out of use. A blocked door takes no new bookings; vehicles already at it are left alone.';
        }
        field(13; "Yard Position Code"; Code[20])
        {
            Caption = 'Waiting position';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the yard position vehicles for this door normally wait in. It is a suggestion offered on arrival, not a rule.';
            TableRelation = "WHA Yard Position"."Code" where("Location Code" = field("Location Code"));
        }
    }

    keys
    {
        key(PK; "Location Code", "Code")
        {
            Clustered = true;
        }
        key(Direction; "Location Code", Direction, Blocked)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, Direction)
        {
        }
        fieldgroup(Brick; "Code", Description, Direction, Blocked)
        {
        }
    }
}
