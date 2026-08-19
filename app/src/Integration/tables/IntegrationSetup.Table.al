namespace WarehouseAdvanced.Integration;

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
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
