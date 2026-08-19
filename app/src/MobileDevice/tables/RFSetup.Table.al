namespace WarehouseAdvanced.MobileDevice;

table 50100 "WHA RF Setup"
{
    Caption = 'Handheld setup';
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
            ToolTip = 'Specifies whether the handheld screen is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; Flow; Enum "WHA RF Flow")
        {
            Caption = 'Flow';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which sequence of steps the handheld takes an operator through. Change this only if another app has added a sequence that suits your warehouse better.';
        }
        field(30; "Require Device Registration"; Boolean)
        {
            Caption = 'Require device registration';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether an operator can only work from a handheld that is registered here. Turn it off while trying the screen out from a desktop.';
        }
        field(40; "Confirm By Scan"; Boolean)
        {
            Caption = 'Confirm by scan';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the operator must scan the bin and the handling unit to prove they are in the right place. Turning it off lets them confirm the whole task in one step, which is quicker but proves nothing.';
        }
        field(50; "Auto Start Task"; Boolean)
        {
            Caption = 'Start work automatically';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a task is marked as started the moment it is handed to an operator, rather than waiting for them to say so. On a handheld there is nothing between being given work and starting it.';
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
