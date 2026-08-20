namespace WarehouseAdvanced.QualityHold;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Journal;
using WarehouseAdvanced.Posting;

table 50550 "WHA Quality Hold Setup"
{
    Caption = 'Quality hold setup';
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
            ToolTip = 'Specifies whether quality hold is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Default Reason"; Enum "WHA Hold Reason")
        {
            Caption = 'Default reason';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason a new hold is given when none is chosen.';
        }
        field(30; "Hold Nested Units"; Boolean)
        {
            Caption = 'Hold what is inside as well';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether holding a handling unit also holds every unit nested inside it. Leave this on: a pallet nobody may touch whose cartons can still be picked is not on hold.';
        }
        field(40; "Require Disposition"; Boolean)
        {
            Caption = 'Decide before releasing';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a hold can only be released once somebody has said what happens to the goods. Leave this on, or a hold can be lifted without anybody deciding anything.';
        }
        field(45; "Hold Blocks Stock"; Enum "WHA Hold Stock Policy")
        {
            Caption = 'What a hold does to stock';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far a hold reaches into Business Central. Leave it as it is and the hold is recorded here only, which is what this app has always done; the other values block the bin the goods stand in, or the whole lot they belong to, so Business Central stops offering them to orders and picks.';
        }
        field(50; "Posting Method"; Enum "WHA Posting Method")
        {
            Caption = 'Write scrapped goods off by';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what releasing a hold with the scrap decision does about the stock. Not writing it off at all is a valid answer, and it is the one a new installation starts on: the goods are out of use in this app and still on hand in Business Central until somebody chooses otherwise.';
        }
        field(51; "Item Journal Template Name"; Code[10])
        {
            Caption = 'Item journal template name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal template the write-off is written to, when it is left in a journal rather than posted.';
            TableRelation = "Item Journal Template".Name where(Type = const(Item));
        }
        field(52; "Item Journal Batch Name"; Code[10])
        {
            Caption = 'Item journal batch name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal batch the write-off is written to, when it is left in a journal rather than posted.';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Item Journal Template Name"));
        }
        field(53; "Posting Reason Code"; Code[10])
        {
            Caption = 'Posting reason code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason code put on every write-off a scrapped hold raises, so goods written off after a quality decision can be told apart from every other adjustment in the ledger.';
            TableRelation = "Reason Code";
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
