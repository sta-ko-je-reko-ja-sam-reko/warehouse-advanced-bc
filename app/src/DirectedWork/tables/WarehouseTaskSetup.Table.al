namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Foundation.NoSeries;
using WarehouseAdvanced.Registration;

table 50200 "WHA Warehouse Task Setup"
{
    Caption = 'Warehouse task setup';
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
            ToolTip = 'Specifies whether directed work is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Default Priority"; Integer)
        {
            Caption = 'Default priority';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the priority given to a new warehouse task when none is entered. A lower number is more urgent, so it is offered to an operator first.';
            MinValue = 0;
        }
        field(30; "Auto Release Tasks"; Boolean)
        {
            Caption = 'Release tasks automatically';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a new warehouse task is released for work as soon as it is created, provided it already names a location and something to move. Leave this off to review tasks before they reach the floor.';
        }
        field(35; "Follow Up Short Picks"; Boolean)
        {
            Caption = 'Raise a follow-up for short picks';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a new warehouse task is raised for whatever an operator could not find. The follow-up is created as a draft, so somebody decides whether it is worth sending a second person to the same bin.';
        }
        field(45; "Write Back To Document"; Boolean)
        {
            Caption = 'Write back to the document';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether finishing a job fills in the quantity to receive or to ship on the warehouse document it came from. Leave it off and the document is untouched, which is what this app has always done; turn it on and finished work reaches the document that will be posted, which is a larger change than it sounds.';
        }
        field(40; "Max Open Tasks Per User"; Integer)
        {
            Caption = 'Max open tasks per user';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many warehouse tasks one person may hold at a time. Zero means no limit.';
            MinValue = 0;
        }
        field(50; "Whse. Registration Method"; Enum "WHA Whse. Reg. Method")
        {
            Caption = 'Warehouse registration method';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what finishing a job tells Business Central about the goods that moved. Leave it as it is and the app keeps the move to itself, which is what this app has always done; register the movement and Business Central''s own bin content and warehouse entries follow the floor.';
        }
        field(90; "Warehouse Task Nos."; Code[20])
        {
            Caption = 'Warehouse task nos.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series used to assign numbers to warehouse tasks.';
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
