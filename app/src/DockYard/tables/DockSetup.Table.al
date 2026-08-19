namespace WarehouseAdvanced.DockYard;

table 50450 "WHA Dock Setup"
{
    Caption = 'Dock and yard setup';
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
            ToolTip = 'Specifies whether the dock and yard feature is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Door Selection"; Enum "WHA Door Selection")
        {
            Caption = 'Choose a door by';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how a door is chosen when a booking does not name one. It only ever chooses between the doors that could take the vehicle anyway.';
        }
        field(21; "Default Slot Minutes"; Integer)
        {
            Caption = 'How long a slot lasts';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how long a booking occupies its door when nobody says otherwise. Two bookings whose slots overlap cannot have the same door.';
            MinValue = 0;
        }
        field(22; "Require Yard Position"; Boolean)
        {
            Caption = 'A waiting vehicle needs a yard position';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a vehicle that arrives before its door is free has to be parked in a named yard position. Turn this on when the yard is big enough that "it is out there somewhere" stops being an answer.';
        }
        field(23; "Late Threshold Minutes"; Integer)
        {
            Caption = 'Late after this many minutes';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how long after its booked time a vehicle that has not arrived counts as late. It changes what is highlighted, never what is allowed.';
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
