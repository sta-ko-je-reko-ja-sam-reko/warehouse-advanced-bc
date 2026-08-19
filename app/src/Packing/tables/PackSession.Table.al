namespace WarehouseAdvanced.Packing;

using System.Security.AccessControl;
using WarehouseAdvanced.HandlingUnit;

table 50402 "WHA Pack Session"
{
    Caption = 'Packing session';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Pack Sessions";
    DrillDownPageId = "WHA Pack Sessions";
    DataCaptionFields = "Entry No.", "Handling Unit No.";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies this piece of packing work.';
            AutoIncrement = true;
        }
        field(10; "Station Code"; Code[20])
        {
            Caption = 'Station code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bench the packing was done at.';
            TableRelation = "WHA Pack Station".Code;
        }
        field(20; "Handling Unit No."; Code[20])
        {
            Caption = 'Carton';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the handling unit being packed — the carton, tote or pallet the goods are going into.';
            TableRelation = "WHA Handling Unit"."No.";
            Editable = false;
        }
        field(30; Status; Enum "WHA Pack Session Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far the packing has got. The status changes through the actions, not by typing.';
            Editable = false;
        }
        field(40; "Packed By User ID"; Code[50])
        {
            Caption = 'Packed by';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who packed the carton.';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(41; "Verified By User ID"; Code[50])
        {
            Caption = 'Verified by';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who checked the carton. It is deliberately recorded separately from who packed it.';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(50; "Started At"; DateTime)
        {
            Caption = 'Started at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when packing began.';
            Editable = false;
        }
        field(51; "Closed At"; DateTime)
        {
            Caption = 'Closed at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the carton was closed.';
            Editable = false;
        }
        field(60; "Line Count"; Integer)
        {
            Caption = 'Kinds of goods';
            ToolTip = 'Specifies how many different kinds of goods are in the carton.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Handling Unit Line" where("Handling Unit No." = field("Handling Unit No.")));
            Editable = false;
        }
        field(61; "Total Quantity"; Decimal)
        {
            Caption = 'Total quantity';
            ToolTip = 'Specifies how much is in the carton in total.';
            FieldClass = FlowField;
            CalcFormula = sum("WHA Handling Unit Line".Quantity where("Handling Unit No." = field("Handling Unit No.")));
            Editable = false;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Carton; "Handling Unit No.")
        {
        }
        key(Work; Status, "Station Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Handling Unit No.", Status)
        {
        }
        fieldgroup(Brick; "Entry No.", "Handling Unit No.", "Station Code", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    trigger OnDelete()
    begin
        Logic().Trigger_OnDelete(Rec);
    end;

    var
        ILogic: Interface "WHA IPackSession";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the packing logic. Used by tests to supply a fake and by
    /// dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IPackSession")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IPackSession"
    var
        DefaultLogic: Codeunit "WHA Pack Session Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
