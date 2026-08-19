namespace WarehouseAdvanced.Core;

table 50001 "WHA Setup Step"
{
    Caption = 'Warehouse advanced setup step';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Step No."; Integer)
        {
            Caption = 'Order';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the order in which the setup step is presented.';
        }
        field(2; Feature; Enum "WHA Feature")
        {
            Caption = 'Feature';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the feature that the setup step configures.';
        }
        field(3; "Has Toggle"; Boolean)
        {
            Caption = 'Has toggle';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the step configures a feature that can be switched on and off. Foundation steps are always on.';
        }
        field(10; Name; Text[100])
        {
            Caption = 'Feature';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the name of the feature that the setup step configures.';
        }
        field(11; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies what the setup step does.';
        }
        field(12; "Setup Page ID"; Integer)
        {
            Caption = 'Detailed setup page';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the full setup page for the feature, for settings not covered by the guided steps.';
        }
        field(20; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the feature is currently switched on.';
        }
        field(30; Status; Enum "WHA Setup Step Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how far the setup step has progressed.';
        }
    }

    keys
    {
        key(PK; "Step No.")
        {
            Clustered = true;
        }
    }
}
