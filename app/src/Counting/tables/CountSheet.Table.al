namespace WarehouseAdvanced.Counting;

using Microsoft.Inventory.Location;
using System.Security.AccessControl;

table 50501 "WHA Count Sheet"
{
    Caption = 'Count sheet';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Count Sheets";
    DrillDownPageId = "WHA Count Sheets";
    DataCaptionFields = "No.", Description;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies the count sheet.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what is being counted, such as the aisle or the round this sheet covers.';
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location being counted. A sheet covers one location.';
            TableRelation = Location;
        }
        field(20; Status; Enum "WHA Count Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the count sheet is in its life. An open sheet is still being built; one that is being counted is on the floor.';
            Editable = false;
        }
        field(21; Selection; Enum "WHA Count Selection")
        {
            Caption = 'Selection';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the sheet gathers when it is filled.';
        }
        field(22; Blind; Boolean)
        {
            Caption = 'Count blind';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the expected quantity is hidden from the person counting until the sheet has been counted.';
        }
        field(30; "Due Date"; Date)
        {
            Caption = 'Due date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the date the count should be finished by.';
        }
        field(31; "Assigned To User ID"; Code[50])
        {
            Caption = 'Assigned to user ID';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who is doing the count.';
            TableRelation = User."User Name";
        }
        field(40; "Started At"; DateTime)
        {
            Caption = 'Started at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the sheet went to the floor.';
            Editable = false;
        }
        field(41; "Counted At"; DateTime)
        {
            Caption = 'Counted at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the last line on the sheet was counted.';
            Editable = false;
        }
        field(42; "Closed At"; DateTime)
        {
            Caption = 'Closed at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the sheet was closed.';
            Editable = false;
        }
        field(50; "Line Count"; Integer)
        {
            Caption = 'Lines';
            ToolTip = 'Specifies how many lines the sheet holds.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Count Sheet Line" where("Sheet No." = field("No.")));
            Editable = false;
        }
        field(51; "Counted Line Count"; Integer)
        {
            Caption = 'Lines counted';
            ToolTip = 'Specifies how many of the sheet''s lines have been counted.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Count Sheet Line" where("Sheet No." = field("No."), Counted = const(true)));
            Editable = false;
        }
        field(52; "Variance Line Count"; Integer)
        {
            Caption = 'Lines that differ';
            ToolTip = 'Specifies how many counted lines came out different from what was expected.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Count Sheet Line" where("Sheet No." = field("No."), Variance = filter(<> 0)));
            Editable = false;
        }
        field(53; "Unapproved Variance Count"; Integer)
        {
            Caption = 'Differences waiting for approval';
            ToolTip = 'Specifies how many lines differ by more than the tolerance and have not been approved yet. A sheet cannot be closed while any remain.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Count Sheet Line" where("Sheet No." = field("No."), "Out of Tolerance" = const(true), Approved = const(false)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Placement; "Location Code", Status)
        {
        }
        key(Assignment; "Assigned To User ID", Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, Status)
        {
        }
        fieldgroup(Brick; "No.", Description, "Location Code", Status)
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
        ILogic: Interface "WHA ICountSheet";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the count sheet logic. Used by tests to supply a fake and
    /// by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA ICountSheet")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA ICountSheet"
    var
        DefaultLogic: Codeunit "WHA Count Sheet Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
