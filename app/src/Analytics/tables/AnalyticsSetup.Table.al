namespace WarehouseAdvanced.Analytics;

using Microsoft.Inventory.Location;

table 50700 "WHA Analytics Setup"
{
    Caption = 'Analytics setup';
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
            ToolTip = 'Specifies whether analytics is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Default Period Days"; Integer)
        {
            Caption = 'Measure the last';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many days a figure covers when nobody gives it dates. A short period reacts quickly and swings about; a long one is steady and hides the week things went wrong.';
            MinValue = 0;
        }
        field(21; "Capture Location Code"; Code[10])
        {
            Caption = 'Capture for location';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which site a captured set of figures is about. Leave it blank to measure the whole company as one, which is right until two sites start behaving differently.';
            TableRelation = Location;
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
