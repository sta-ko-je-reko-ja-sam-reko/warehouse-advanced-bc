namespace WarehouseAdvanced.HandlingUnit;

using Microsoft.Foundation.NoSeries;

table 50050 "WHA Handling Unit Setup"
{
    Caption = 'Handling unit setup';
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
            ToolTip = 'Specifies whether handling unit functionality is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Allow Nesting"; Boolean)
        {
            Caption = 'Allow nesting';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a handling unit can be placed inside another handling unit, so that moving the outer one moves everything it contains.';
        }
        field(30; "Max Nesting Depth"; Integer)
        {
            Caption = 'Max nesting depth';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many levels of handling unit may be nested inside one another. Zero means no limit.';
            MinValue = 0;
        }
        field(90; "Handling Unit Nos."; Code[20])
        {
            Caption = 'Handling unit nos.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series used to assign numbers to handling units.';
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
