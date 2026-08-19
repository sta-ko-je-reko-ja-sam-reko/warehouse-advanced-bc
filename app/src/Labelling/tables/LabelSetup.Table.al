namespace WarehouseAdvanced.Labelling;

table 50600 "WHA Label Setup"
{
    Caption = 'Labelling setup';
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
            ToolTip = 'Specifies whether labelling is enabled. Turning this on shows the related pages and actions, and the session restarts so the change takes effect.';
        }
        field(20; Format; Enum "WHA Label Code Format")
        {
            Caption = 'Format';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what a label code looks like. Use SSCC if your trading partners expect a GS1 code; use a sequential licence plate if the numbers are only for use inside this warehouse.';
        }
        field(30; "GS1 Company Prefix"; Code[10])
        {
            Caption = 'GS1 company prefix';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the company prefix GS1 issued to you. It is the part of every SSCC that says the code came from this company, and it must be exactly the digits GS1 gave you.';
        }
        field(31; "Extension Digit"; Integer)
        {
            Caption = 'Extension digit';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the first digit of every SSCC. It is yours to choose and is normally used to say something about the size of the unit. Leave it at zero if it means nothing to you.';
            MinValue = 0;
            MaxValue = 9;
        }
        field(40; "Last Serial Reference"; BigInteger)
        {
            Caption = 'Last serial reference';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the last number used in a label code. It only ever counts up, because a number that comes round again is a second label with the same code on it.';
            Editable = false;
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
