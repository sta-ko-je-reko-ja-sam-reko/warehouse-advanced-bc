namespace WarehouseAdvanced.Posting;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 50750 "WHA Posting Request"
{
    Caption = 'Posting request';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the position of the line within the request.';
        }
        field(10; "Posting Type"; Enum "WHA Posting Type")
        {
            Caption = 'Posting type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which way the stock moves. The quantity is always positive; this says whether it is being added or taken away.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item whose stock is being changed.';
            TableRelation = Item."No.";
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant whose stock is being changed.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of measure code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unit the quantity is expressed in. Blank leaves the item''s base unit of measure to decide.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how much stock is being added or taken away, always as a positive number.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the stock is being changed.';
            TableRelation = Location;
        }
        field(21; "Bin Code"; Code[20])
        {
            Caption = 'Bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the stock is being changed in, at a location that keeps bins.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(30; "Lot No."; Code[50])
        {
            Caption = 'Lot no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the lot the stock belongs to, for an item that is tracked by lot.';
        }
        field(31; "Serial No."; Code[50])
        {
            Caption = 'Serial no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the serial number of the stock, for an item that is tracked by serial number.';
        }
        field(40; "Posting Date"; Date)
        {
            Caption = 'Posting date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the date the change is posted under.';
        }
        field(41; "Document No."; Code[20])
        {
            Caption = 'Document no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the document number the change is posted under, which is what links the ledger entry back to what caused it.';
        }
        field(42; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the description carried onto the journal line.';
        }
        field(43; "Reason Code"; Code[10])
        {
            Caption = 'Reason code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason code carried onto the journal line.';
            TableRelation = "Reason Code";
        }
        field(44; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal template name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal template the line is written to, when the lines are left in a journal rather than posted.';
            TableRelation = "Item Journal Template".Name;
        }
        field(45; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal batch name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal batch the line is written to, when the lines are left in a journal rather than posted.';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(50; "Source Table No."; Integer)
        {
            Caption = 'Source table no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the table the line was raised from, so what asked for the change can be found again.';
        }
        field(51; "Source No."; Code[20])
        {
            Caption = 'Source no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the record the line was raised from, such as the count sheet or the hold.';
        }
        field(52; "Source Line No."; Integer)
        {
            Caption = 'Source line no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the line of the record the request was raised from, so what happened to it can be written back against the right line.';
        }
        field(60; Posted; Boolean)
        {
            Caption = 'Posted';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this line reached the item ledger. A line left in a journal for somebody to look at has not.';
        }
        field(61; "Journal Line No."; Integer)
        {
            Caption = 'Journal line no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal line the request was written to, when the lines are left in a journal rather than posted.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
