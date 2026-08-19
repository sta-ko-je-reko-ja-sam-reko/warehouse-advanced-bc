namespace WarehouseAdvanced.LabourManagement;

using Microsoft.Inventory.Location;
using WarehouseAdvanced.DirectedWork;

table 50351 "WHA Labour Standard"
{
    Caption = 'Labour standard';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Labour Standards";
    DrillDownPageId = "WHA Labour Standards";
    DataCaptionFields = "Location Code", "Task Type";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the standard applies to. Leave it blank for a standard that applies everywhere you have not set one.';
            TableRelation = Location;
        }
        field(2; "Task Type"; Enum "WHA Warehouse Task Type")
        {
            Caption = 'Task type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the kind of work the standard applies to.';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the standard covers and where the numbers came from.';
        }
        field(20; Basis; Enum "WHA Labour Standard Basis")
        {
            Caption = 'Basis';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how the expected time is worked out from the standard.';
        }
        field(21; "Minutes Per Job"; Decimal)
        {
            Caption = 'Minutes per job';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how long the job itself should take, before anything is counted. This is the walking, the scanning and the paperwork.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                Logic().Validate_Minutes(Rec, xRec);
            end;
        }
        field(22; "Minutes Per Unit"; Decimal)
        {
            Caption = 'Minutes per unit';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how long each unit handled should add to the job. It is ignored when the basis is per job only.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                Logic().Validate_Minutes(Rec, xRec);
            end;
        }
        field(30; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the standard is ignored. Work measured against a blocked standard is recorded with no expected time rather than against a number nobody trusts.';
        }
    }

    keys
    {
        key(PK; "Location Code", "Task Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Location Code", "Task Type", "Minutes Per Job")
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    var
        ILogic: Interface "WHA ILabourStandardRule";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the labour standard logic. Used by tests to supply a fake
    /// and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA ILabourStandardRule")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA ILabourStandardRule"
    var
        DefaultLogic: Codeunit "WHA Labour Std. Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
