namespace WarehouseAdvanced.Counting;

table 50500 "WHA Count Setup"
{
    Caption = 'Counting setup';
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
            ToolTip = 'Specifies whether counting is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Default Selection"; Enum "WHA Count Selection")
        {
            Caption = 'Default selection';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what a new count sheet gathers when it is filled, unless the sheet itself says otherwise.';
        }
        field(21; "Blind Counting"; Boolean)
        {
            Caption = 'Count blind';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a new count sheet hides the expected quantity from the person counting. A counter who can see the expected number tends to write it down.';
        }
        field(30; "Tolerance Quantity"; Decimal)
        {
            Caption = 'Tolerance quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far a count may differ from the expected quantity before somebody has to look at it. Zero allows no difference at all.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(31; "Tolerance Percent"; Decimal)
        {
            Caption = 'Tolerance percent';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far a count may differ from the expected quantity, as a percentage of it. A line is within tolerance when it passes either this or the tolerance quantity, whichever is the more generous.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
        field(40; "Approve Variances"; Boolean)
        {
            Caption = 'Approve differences above tolerance';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a count sheet can only be closed once somebody has approved every line that differs by more than the tolerance. Leave this on unless the warehouse has another way of reviewing differences.';
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
