namespace WarehouseAdvanced.Analytics;

using Microsoft.Inventory.Location;
using System.Security.AccessControl;

table 50701 "WHA KPI Snapshot"
{
    Caption = 'KPI snapshot';
    DataClassification = CustomerContent;
    LookupPageId = "WHA KPI Snapshots";
    DrillDownPageId = "WHA KPI Snapshots";
    DataCaptionFields = "Entry No.", Measure;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies this figure.';
            AutoIncrement = true;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the site the figure is about. Blank means the whole company was measured as one.';
            TableRelation = Location;
            Editable = false;
        }
        field(11; Measure; Enum "WHA KPI Measure")
        {
            Caption = 'Measure';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what was measured.';
            Editable = false;
        }
        field(20; "From Date"; Date)
        {
            Caption = 'From date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the first day the figure counts.';
            Editable = false;
        }
        field(21; "To Date"; Date)
        {
            Caption = 'To date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the last day the figure counts. Two figures are only worth comparing when they cover periods of the same length.';
            Editable = false;
        }
        field(30; Value; Decimal)
        {
            Caption = 'Value';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the figure itself. Zero means there was nothing to measure as often as it means something went badly, so read it beside the period.';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }
        field(31; "Measured In"; Text[30])
        {
            Caption = 'Measured in';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unit the figure is in, kept with the figure so an old snapshot still reads correctly if the measure is ever redefined.';
            Editable = false;
        }
        field(40; "Captured At"; DateTime)
        {
            Caption = 'Captured at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the figure was taken.';
            Editable = false;
        }
        field(41; "Captured By User ID"; Code[50])
        {
            Caption = 'Captured by';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who took the figure, or which job did.';
            TableRelation = User."User Name";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Period; "Location Code", Measure, "To Date")
        {
        }
        key(Trend; Measure, "To Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Measure, Value)
        {
        }
        fieldgroup(Brick; Measure, Value, "Measured In", "To Date")
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    var
        ILogic: Interface "WHA IKpiSnapshot";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the snapshot logic. Used by tests to supply a fake and by
    /// dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IKpiSnapshot")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IKpiSnapshot"
    var
        DefaultLogic: Codeunit "WHA KPI Snapshot Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
