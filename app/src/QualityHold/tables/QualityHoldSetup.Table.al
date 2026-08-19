namespace WarehouseAdvanced.QualityHold;

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
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
