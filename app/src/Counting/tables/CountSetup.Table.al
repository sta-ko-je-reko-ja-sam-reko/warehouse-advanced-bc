namespace WarehouseAdvanced.Counting;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;
using WarehouseAdvanced.Posting;

table 50500 "WHA Count Setup"
{
    Caption = 'Counting setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary key';
            DataClassification = CustomerContent;
        }
        field(10; "WHA Enabled"; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether counting is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Default Selection"; Enum "WHA Count Selection")
        {
            Caption = 'Default selection';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what a new count sheet gathers when it is filled, unless the sheet itself says otherwise.';
        }
        field(21; "Blind Counting"; Boolean)
        {
            Caption = 'Count blind';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a new count sheet hides the expected quantity from the person counting. A counter who can see the expected number tends to write it down.';
        }
        field(30; "Tolerance Quantity"; Decimal)
        {
            Caption = 'Tolerance quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far a count may differ from the expected quantity before somebody has to look at it. Zero allows no difference at all.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(31; "Tolerance Percent"; Decimal)
        {
            Caption = 'Tolerance percent';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far a count may differ from the expected quantity, as a percentage of it. A line is within tolerance when it passes either this or the tolerance quantity, whichever is the more generous.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
        field(40; "Approve Variances"; Boolean)
        {
            Caption = 'Approve differences above tolerance';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a count sheet can only be closed once somebody has approved every line that differs by more than the tolerance. Leave this on unless the warehouse has another way of reviewing differences.';
        }
        field(50; "Posting Method"; Enum "WHA Posting Method")
        {
            Caption = 'Post differences by';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what closing a count sheet does about the differences it found. Not posting at all is a valid answer, and it is the one a new installation starts on: nothing reaches the item ledger until somebody chooses that it should.';
        }
        field(51; "Item Journal Template Name"; Code[10])
        {
            Caption = 'Item journal template name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal template the differences are written to, when they are left in a journal rather than posted.';
            TableRelation = "Item Journal Template".Name where(Type = const(Item));
        }
        field(52; "Item Journal Batch Name"; Code[10])
        {
            Caption = 'Item journal batch name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal batch the differences are written to, when they are left in a journal rather than posted.';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Item Journal Template Name"));
        }
        field(53; "Posting Reason Code"; Code[10])
        {
            Caption = 'Posting reason code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason code put on every adjustment a count sheet raises, so counting differences can be told apart from every other adjustment in the ledger.';
            TableRelation = "Reason Code";
        }
        field(90; "Count Sheet Nos."; Code[20])
        {
            Caption = 'Count sheet nos.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series used to assign numbers to count sheets.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
