namespace WarehouseAdvanced.Integration;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Journal;
using WarehouseAdvanced.Posting;

table 50650 "WHA Integration Setup"
{
    Caption = 'Integration setup';
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
            ToolTip = 'Specifies whether the integration surface is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Partner System"; Code[20])
        {
            Caption = 'Partner system';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code that identifies the system exchanging messages with this one. It is stamped on every message so that a company exchanging with more than one system can still tell them apart.';
        }
        field(30; "Auto Process Inbound"; Boolean)
        {
            Caption = 'Process inbound messages on arrival';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether an inbound message is applied as soon as it arrives. Leave this off to review messages before they change anything, and process them from the message list or on a schedule.';
        }
        field(35; "Release Requested Work"; Boolean)
        {
            Caption = 'Release requested work';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether work the partner system asks for goes straight to the floor. Turn this off to hold requested work as a draft for someone here to check before it is released. A single message can say otherwise for itself.';
        }
        field(40; "Max Retry Count"; Integer)
        {
            Caption = 'Max retry count';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many times a failed message may be tried again before it is left alone for someone to look at. Zero means it is never retried automatically.';
            MinValue = 0;
        }
        field(50; "Posting Method"; Enum "WHA Posting Method")
        {
            Caption = 'Posting method';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what an inventory adjustment sent by the partner system does to stock. It can be recorded and nothing more, written to a journal for somebody here to look at before posting, or posted straight to the ledger.';
        }
        field(51; "Item Journal Template Name"; Code[10])
        {
            Caption = 'Item journal template name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal template an adjustment is written to. Only used when the posting method writes journal lines.';
            TableRelation = "Item Journal Template".Name;
        }
        field(52; "Item Journal Batch Name"; Code[10])
        {
            Caption = 'Item journal batch name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item journal batch an adjustment is written to. Only used when the posting method writes journal lines.';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Item Journal Template Name"));
        }
        field(53; "Posting Reason Code"; Code[10])
        {
            Caption = 'Posting reason code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason code stamped on an adjustment that came from the partner system, so the entries it makes can be told apart from everything else later.';
            TableRelation = "Reason Code".Code;
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
