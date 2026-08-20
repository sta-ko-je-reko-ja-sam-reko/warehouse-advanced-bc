namespace WarehouseAdvanced.Registration;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 50800 "WHA Whse. Move Request"
{
    Caption = 'Warehouse move request';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the position of the move within the request.';
        }
        field(2; "Change Type"; Enum "WHA Whse. Change Type")
        {
            Caption = 'Change type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what happened to the goods. A move has a bin at both ends; the goods being added to or taken out of a bin has one end only, because the other end is the item ledger.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item that was moved.';
            TableRelation = Item."No.";
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant that was moved.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of measure code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unit the quantity is expressed in. Blank leaves the item''s base unit of measure to decide.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how much was moved, always as a positive number.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the move happened at. A move never crosses locations.';
            TableRelation = Location;
        }
        field(21; "From Bin Code"; Code[20])
        {
            Caption = 'From bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the goods were taken from.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(22; "To Bin Code"; Code[20])
        {
            Caption = 'To bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the goods were put into.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(30; "Lot No."; Code[50])
        {
            Caption = 'Lot no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the lot that was moved, for an item that is tracked by lot.';
        }
        field(31; "Serial No."; Code[50])
        {
            Caption = 'Serial no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the serial number that was moved, for an item that is tracked by serial number.';
        }
        field(40; "Registering Date"; Date)
        {
            Caption = 'Registering date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the date the move is registered under.';
        }
        field(41; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the description carried onto the warehouse entry.';
        }
        field(42; "Reference No."; Code[20])
        {
            Caption = 'Reference no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what asked for the move, which is what links the warehouse entry back to the job the operator finished.';
        }
        field(50; "Source Table No."; Integer)
        {
            Caption = 'Source table no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the table the move was raised from, so what asked for it can be found again.';
        }
        field(51; "Source No."; Code[20])
        {
            Caption = 'Source no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the record the move was raised from, such as the warehouse task.';
        }
        field(60; Registered; Boolean)
        {
            Caption = 'Registered';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this move reached the warehouse entries. A move at a location that keeps no bins has not, because there is nothing there to record it against.';
        }
        field(61; "Warehouse Entry No."; Integer)
        {
            Caption = 'Warehouse entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the last warehouse entry the registration produced, so the move can be traced into Business Central''s own records.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Item; "Item No.", "Location Code")
        {
        }
    }
}
