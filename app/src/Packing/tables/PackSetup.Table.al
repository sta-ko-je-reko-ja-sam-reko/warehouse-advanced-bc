namespace WarehouseAdvanced.Packing;

table 50400 "WHA Pack Setup"
{
    Caption = 'Packing setup';
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
            ToolTip = 'Specifies whether packing is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Require Verification"; Boolean)
        {
            Caption = 'Require verification';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether somebody must confirm what is in a carton before it can be closed. Turning this off makes packing quicker and means nothing was checked.';
        }
        field(30; "Close Unit When Closed"; Boolean)
        {
            Caption = 'Close the handling unit too';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether closing a packing session also closes the carton itself, so nothing more can be added to it. This is normally what you want: the carton has been taped shut.';
        }
        field(40; "Default Station Code"; Code[20])
        {
            Caption = 'Default station';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the packing station offered first when somebody starts packing.';
            TableRelation = "WHA Pack Station".Code;
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
