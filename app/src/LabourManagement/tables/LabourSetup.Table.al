namespace WarehouseAdvanced.LabourManagement;

table 50350 "WHA Labour Setup"
{
    Caption = 'Labour setup';
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
            ToolTip = 'Specifies whether labour management is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Default Basis"; Enum "WHA Labour Standard Basis")
        {
            Caption = 'Default basis';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how a new standard works out expected time, unless the standard itself says otherwise.';
        }
        field(40; "Look Back Days"; Integer)
        {
            Caption = 'Look back over';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many days of finished work a scheduled run reads. The run skips work that already has an entry, so a short window costs less and misses nothing while the run happens often enough. Zero reads every job the warehouse has ever finished, which is correct and gets slower for ever.';
            MinValue = 0;
        }
        field(30; "Max Job Minutes"; Decimal)
        {
            Caption = 'Longest believable job, in minutes';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how long a job can take before the time is treated as somebody forgetting to close it rather than as work. Such time is still recorded, but it is not measured against a standard. Zero believes everything.';
            DecimalPlaces = 0 : 5;
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
