namespace WarehouseAdvanced.Replenishment;

table 50250 "WHA Repl. Setup"
{
    Caption = 'Replenishment setup';
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
            ToolTip = 'Specifies whether replenishment is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; "Default Method"; Enum "WHA Repl. Method")
        {
            Caption = 'Default method';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how a new rule measures what is in its pick bin, unless the rule itself says otherwise.';
        }
        field(21; "Default Priority"; Integer)
        {
            Caption = 'Default priority for replenishment work';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the priority given to the work a rule raises, unless the rule itself says otherwise. A lower number is more urgent, so it is offered to an operator first.';
            MinValue = 0;
        }
        field(22; "Demand Method"; Enum "WHA Repl. Demand")
        {
            Caption = 'Measure a bin against';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a run takes work already planned out of a bin into account, as well as what is in it. Looking only at what is there is what a new installation starts on, and it is the answer that misses a pick face a wave is about to empty.';
        }
        field(30; "Release Replenishment Work"; Boolean)
        {
            Caption = 'Send replenishment work to the floor';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the work a run raises goes to the floor immediately. Leave this off to look at what a run proposed before anybody is sent to do it.';
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
