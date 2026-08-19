namespace WarehouseAdvanced.WaveManagement;

using Microsoft.Foundation.NoSeries;

table 50150 "WHA Wave Setup"
{
    Caption = 'Wave setup';
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
            ToolTip = 'Specifies whether wave management is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Default Strategy"; Enum "WHA Wave Strategy")
        {
            Caption = 'Default strategy';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how a new wave chooses its work, unless the wave itself says otherwise.';
        }
        field(30; "Default Max Tasks"; Integer)
        {
            Caption = 'Default max jobs per wave';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many jobs a wave takes when it is filled, unless the wave itself says otherwise. A wave bigger than a shift can finish is a wave nobody trusts.';
            MinValue = 0;
        }
        field(40; "Include Unreleased Work"; Boolean)
        {
            Caption = 'Gather work that is not released yet';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a wave may gather jobs that are still drafts and release them with the wave. Leave this off to gather only work that has already been approved for the floor.';
        }
        field(90; "Wave Nos."; Code[20])
        {
            Caption = 'Wave nos.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series used to assign numbers to waves.';
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
