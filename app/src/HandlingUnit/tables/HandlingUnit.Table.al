namespace WarehouseAdvanced.HandlingUnit;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 50051 "WHA Handling Unit"
{
    Caption = 'Handling unit';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Handling Units";
    DrillDownPageId = "WHA Handling Units";
    DataCaptionFields = "No.", Description;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies the handling unit.';
            NotBlank = true;
        }
        field(2; SSCC; Code[20])
        {
            Caption = 'SSCC';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the serial shipping container code printed on the handling unit label. It identifies the unit to trading partners.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the handling unit contains or what it is used for.';
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location where the handling unit currently is.';
            TableRelation = Location;

            trigger OnValidate()
            begin
                Logic().Validate_LocationCode(Rec, xRec);
            end;
        }
        field(11; "Bin Code"; Code[20])
        {
            Caption = 'Bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin where the handling unit currently is.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(20; "Parent No."; Code[20])
        {
            Caption = 'Parent handling unit';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the handling unit that this one is placed inside. Moving the outer unit moves this one with it.';
            TableRelation = "WHA Handling Unit"."No.";

            trigger OnValidate()
            begin
                Logic().Validate_ParentNo(Rec, xRec);
            end;
        }
        field(30; Status; Enum "WHA Handling Unit Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the handling unit is in its life cycle. An open unit can still be changed; a closed one is ready to ship.';
        }
        field(40; "Nested Unit Count"; Integer)
        {
            Caption = 'Nested units';
            ToolTip = 'Specifies how many handling units are placed directly inside this one.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Handling Unit" where("Parent No." = field("No.")));
            Editable = false;
        }
        field(41; "Total Quantity"; Decimal)
        {
            Caption = 'Total quantity';
            ToolTip = 'Specifies the total quantity of goods recorded on the handling unit.';
            FieldClass = FlowField;
            CalcFormula = sum("WHA Handling Unit Line".Quantity where("Handling Unit No." = field("No.")));
            Editable = false;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Parent; "Parent No.")
        {
        }
        key(Placement; "Location Code", "Bin Code")
        {
        }
        key(Sscc; SSCC)
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
        ILogic: Interface "WHA IHandlingUnit";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the handling unit logic. Used by tests to supply a fake
    /// and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IHandlingUnit")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IHandlingUnit"
    var
        DefaultLogic: Codeunit "WHA Handling Unit Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
