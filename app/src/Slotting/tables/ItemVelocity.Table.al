namespace WarehouseAdvanced.Slotting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 50301 "WHA Item Velocity"
{
    Caption = 'Item velocity';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Item Velocities";
    DrillDownPageId = "WHA Item Velocities";
    DataCaptionFields = "Location Code", "Item No.";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the movement was measured at.';
            TableRelation = Location;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item that was measured.';
            TableRelation = Item."No.";
        }
        field(3; "Variant Code"; Code[10])
        {
            Caption = 'Variant code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant that was measured.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(10; Movements; Integer)
        {
            Caption = 'Picks';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many times the item was picked over the period. One pick is one trip, whatever was taken.';
            Editable = false;
        }
        field(11; "Quantity Moved"; Decimal)
        {
            Caption = 'Quantity picked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how much of the item was picked over the period.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(20; "Rank Value"; Decimal)
        {
            Caption = 'Ranked on';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the figure the item was ranked on, which is whichever of picks or quantity the setup chose. It is kept so the ranking can be checked rather than trusted.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; Class; Enum "WHA Velocity Class")
        {
            Caption = 'Class';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how fast the item moves compared with everything else at the location.';
            Editable = false;
        }
        field(30; "From Date"; Date)
        {
            Caption = 'From date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the first day the analysis counted.';
            Editable = false;
        }
        field(31; "To Date"; Date)
        {
            Caption = 'To date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the last day the analysis counted.';
            Editable = false;
        }
        field(32; "Calculated At"; DateTime)
        {
            Caption = 'Calculated at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the analysis was run. A class is only as current as the run that produced it.';
            Editable = false;
        }
        field(40; "Main Bin Code"; Code[20])
        {
            Caption = 'Picked most often from';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the item was picked from most often over the period. That is the bin a proposal is about.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            Editable = false;
        }
        field(41; "Main Bin Ranking"; Integer)
        {
            Caption = 'Ranking of that bin';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the ranking of the bin the item is picked from most often. A higher ranking is a better bin.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Location Code", "Item No.", "Variant Code")
        {
            Clustered = true;
        }
        key(Ranking; "Location Code", "Rank Value")
        {
        }
        key(Class; "Location Code", Class)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", Class, Movements)
        {
        }
        fieldgroup(Brick; "Item No.", Class, Movements, "Main Bin Code")
        {
        }
    }
}
