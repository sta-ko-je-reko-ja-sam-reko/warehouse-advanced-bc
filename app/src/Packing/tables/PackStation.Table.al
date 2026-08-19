namespace WarehouseAdvanced.Packing;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 50401 "WHA Pack Station"
{
    Caption = 'Packing station';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Pack Stations";
    DrillDownPageId = "WHA Pack Stations";
    DataCaptionFields = "Code", Description;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code that identifies the packing bench.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which bench this is, so people know where to go.';
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the bench stands in. Cartons packed here are created at that location.';
            TableRelation = Location;
        }
        field(11; "Bin Code"; Code[20])
        {
            Caption = 'Bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin cartons packed at this bench are put in, which is normally the bench itself or the outbound staging area next to it.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(20; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the bench is out of use. Nobody can start packing at a blocked bench.';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(Placement; "Location Code", Blocked)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Location Code")
        {
        }
        fieldgroup(Brick; "Code", Description, "Location Code", Blocked)
        {
        }
    }
}
