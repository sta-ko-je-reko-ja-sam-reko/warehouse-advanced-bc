namespace WarehouseAdvanced.Slotting;

table 50300 "WHA Slotting Setup"
{
    Caption = 'Slotting setup';
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
            ToolTip = 'Specifies whether slotting is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; Basis; Enum "WHA Velocity Basis")
        {
            Caption = 'Rank items on';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what makes an item fast moving: how often it is picked, or how much of it is picked.';
        }
        field(21; "Analysis Period Days"; Integer)
        {
            Caption = 'Look back this many days';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far back an analysis looks when nobody gives it dates. Too short and a seasonal line looks dead; too long and a line that stopped selling keeps its good bin.';
            MinValue = 0;
        }
        field(22; "Min Movements"; Integer)
        {
            Caption = 'Fewest picks worth classifying';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many picks an item needs before it is given a class at all. An item picked once is not slow moving; it is unmeasured.';
            MinValue = 0;
        }
        field(30; "Class A Percent"; Decimal)
        {
            Caption = 'Class A percent';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the share of all movement that the fastest items account for. The usual answer is that a fifth of the items account for most of the work.';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
        }
        field(31; "Class B Percent"; Decimal)
        {
            Caption = 'Class B percent';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the share of all movement, after class A, that the medium items account for. Everything left over is class C.';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
        }
        field(40; "Class A Min Bin Ranking"; Integer)
        {
            Caption = 'Class A needs a bin ranked at least';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin ranking a fast-moving item deserves. An item ranked A that is picked from a worse bin is proposed for re-slotting.';
            MinValue = 0;
        }
        field(41; "Class B Min Bin Ranking"; Integer)
        {
            Caption = 'Class B needs a bin ranked at least';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin ranking a medium-moving item deserves. Class C is left wherever it is.';
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
